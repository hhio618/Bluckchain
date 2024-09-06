import {
  MarketCreated,
  OrderPlaced,
  OrderMatched,
  OrderCancelled,
  MarketSettled,
  RewardClaimed,
  Swap,
  PredictionMarket,
} from "../generated/PredictionMarket/PredictionMarket";
import { Market, User, Order, Bet } from "../generated/schema";
import { BigInt, log } from "@graphprotocol/graph-ts";

export function handleMarketCreated(event: MarketCreated): void {
  let market = new Market(event.params.marketId.toString());
  market.eventId = event.params.eventId;
  market.totalLocked = BigInt.fromI32(0);
  market.outcomeLocked = [];
  market.outcomePrices = [];
  market.totalShares = BigInt.fromI32(0);
  market.settled = false;
  market.save();
}

export function handleOrderPlaced(event: OrderPlaced): void {
  let order = new Order(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString(),
  );
  order.trader = event.params.trader.toHex();
  order.market = event.params.marketId.toString();
  order.outcome = event.params.outcome;
  order.share = event.params.amount;
  order.price = event.params.price;
  order.isBuy = event.params.isLimit;
  order.isLimit = true;
  order.timestamp = event.block.timestamp;
  order.save();

  // Update user and market stats
  let user = User.load(event.params.trader.toHex());
  if (user == null) {
    user = new User(event.params.trader.toHex());
    user.volumeTraded = BigInt.fromI32(0);
    user.unsettledVolume = BigInt.fromI32(0);
    user.profit = BigInt.fromI32(0);
    user.potentialProfit = BigInt.fromI32(0);
  }
  user.volumeTraded = user.volumeTraded.plus(order.share.times(order.price));
  user.save();
}

export function handleOrderMatched(event: OrderMatched): void {
  let order = Order.load(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString(),
  );
  if (order) {
    order.share = order.share.minus(event.params.amount);
    if (order.share.equals(BigInt.fromI32(0))) {
      order.save();
    }
  }

  // Update user's unsettled volume
  let user = User.load(event.params.buyer.toHex());
  if (user == null) {
    user = new User(event.params.buyer.toHex());
    user.volumeTraded = BigInt.fromI32(0);
    user.unsettledVolume = BigInt.fromI32(0);
    user.profit = BigInt.fromI32(0);
    user.potentialProfit = BigInt.fromI32(0);
  }
  user.unsettledVolume = user.unsettledVolume.plus(
    event.params.amount.times(event.params.price),
  );
  user.save();
}

export function handleOrderCancelled(event: OrderCancelled): void {
  let order = Order.load(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString(),
  );
  if (order) {
    order.share = BigInt.fromI32(0);
    order.save();
  }

  // Update user's unsettled volume
  let user = User.load(event.params.trader.toHex());
  if (user == null) {
    user = new User(event.params.trader.toHex());
    user.volumeTraded = BigInt.fromI32(0);
    user.unsettledVolume = BigInt.fromI32(0);
    user.profit = BigInt.fromI32(0);
    user.potentialProfit = BigInt.fromI32(0);
  }
  user.unsettledVolume = user.unsettledVolume.minus(
    event.params.amount.times(event.params.price),
  );
  user.save();
}

export function handleMarketSettled(event: MarketSettled): void {
  let market = Market.load(event.params.marketId.toString());
  if (market != null) {
    market.settled = true;
    market.finalOutcome = event.params.outcome;
    market.save();
  }
}

export function handleRewardClaimed(event: RewardClaimed): void {
  let user = User.load(event.params.user.toHex());
  if (user != null) {
    user.profit = user.profit.plus(event.params.reward);
    user.save();
  }
}

export function handleSwap(event: Swap): void {
  let market = Market.load(event.params.marketId.toString());
  if (market == null) {
    log.warning("Market not found: {}", [event.params.marketId.toString()]);
    return;
  }

  let user = User.load(event.params.trader.toHex());
  if (user == null) {
    user = new User(event.params.trader.toHex());
    user.volumeTraded = BigInt.fromI32(0);
    user.unsettledVolume = BigInt.fromI32(0);
    user.profit = BigInt.fromI32(0);
    user.potentialProfit = BigInt.fromI32(0);
  }

  // Calculate the new outcome price and update user shares
  let outcomePrice = market.outcomePrices[event.params.outcome.toI32()];
  let potentialProfit = outcomePrice
    .times(event.params.amountOut)
    .minus(event.params.amountIn);
  user.potentialProfit = user.potentialProfit.plus(potentialProfit);
  user.save();

  // Update market stats
  market.totalLocked = market.totalLocked.plus(event.params.amountIn);
  market.outcomeLocked[event.params.outcome.toI32()] = market.outcomeLocked[
    event.params.outcome.toI32()
  ].plus(event.params.amountIn);
  market.totalShares = market.totalShares.plus(event.params.amountOut);

  // market.outcomeShares[event.params.outcome.toI32()] = market.outcomeShares[
  //  event.params.outcome.toI32()
  // ].plus(event.params.amountOut);
  market.save();
}
