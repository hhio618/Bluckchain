// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EventOracle.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract PredictionMarket is Ownable {
    using Math for uint256;

    EventOracle public eventOracle;
    IERC20 public bluckToken;
    address private callback_sender;

    struct Order {
        address trader;
        uint256 share;
        uint256 price;
        bool isBuy; // true for buy order, false for sell order
        bool isLimit; // true for limit order, false for market order
    }

    struct Market {
        uint256 eventId;
        uint256 totalLocked;
        uint256[] outcomeLocked;
        uint256[] outcomePrices;
        uint256 totalShares;
        uint256 totalBetters;
        uint256[] outcomeShares;
        mapping(address => mapping(uint256 => uint256)) userShares;
        uint256 finalOutcome;
        mapping(address => bool) rewardClaimed;
        bool settled;
        uint256 outcomeCount;
        mapping(uint256 => Order[]) orderBooks;
    }

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    uint256 public marketFee = 30; // 0.3% fee (30 / 10000)
    uint256 public accumulatedFees;

    event MarketCreated(uint256 indexed marketId, uint256 indexed eventId);
    event MarketSettled(uint256 indexed marketId, uint256 outcome);
    event FeesWithdrawn(uint256 amount);
    event OrderPlaced(
        uint256 indexed marketId,
        uint256 indexed outcome,
        uint256 amount,
        uint256 price,
        address indexed trader,
        bool isLimit
    );
    event OrderCancelled(
        address indexed trader,
        uint256 indexed marketId,
        uint256 indexed outcome,
        uint256 amount,
        uint256 price,
        bool isBuy
    );
    event OrderMatched(
        uint256 indexed marketId,
        uint256 indexed outcome,
        uint256 amount,
        uint256 price,
        address indexed buyer,
        address seller
    );

    event RewardClaimed(
        address indexed user, uint256 indexed marketId, uint256 outcome, uint256 shares, uint256 reward
    );
    event Swap(
        uint256 indexed marketId, uint256 indexed outcome, uint256 amountIn, uint256 amountOut, address indexed trader
    );
    event BetPlaced(address indexed user, uint256 indexed marketId, uint256 outcome, uint256 shares, uint256 price);
    event Log(string log, uint256 value);

    constructor(address _eventOracle, address _bluckToken, address _callback_sender) Ownable(msg.sender) {
        eventOracle = EventOracle(_eventOracle);
        bluckToken = IERC20(_bluckToken);
        callback_sender = _callback_sender;
    }

    modifier onlyReactive() {
        if (callback_sender != address(0)) {
            require(msg.sender == callback_sender, "Unauthorized");
        }
        _;
    }

    function getMarketDetails(uint256 _marketId)
        public
        returns (
            uint256 eventId,
            uint256 totalLocked,
            bool marketSettled,
            uint256 eventOutcome,
            string memory description,
            uint256 endTime,
            string[] memory outcomeNames,
            uint256[] memory outcomePrices,
            uint256[] memory outcomeChances
        )
    {
        Market storage market = markets[_marketId];
        (description, endTime,, eventOutcome, outcomeNames) = eventOracle.getEventDetails(market.eventId);

        uint256[] memory outcomeChances = getMarketOutcomeChances(_marketId);
        uint256[] memory outcomePrices = market.outcomePrices;
        return (
            market.eventId,
            market.totalLocked,
            market.settled,
            eventOutcome,
            description,
            endTime,
            outcomeNames,
            outcomePrices,
            outcomeChances
        );
    }

    function getMarketOutcomeChances(uint256 _marketId) public returns (uint256[] memory chances) {
        Market storage market = markets[_marketId];
        chances = new uint256[](market.outcomeCount);
        if (market.totalShares == 0) {
            for (uint256 i = 0; i < market.outcomeCount; i++) {
                chances[i] = 1e2 / market.outcomeCount;
            }
        } else {
            for (uint256 i = 0; i < market.outcomeCount; i++) {
                chances[i] = market.outcomeShares[i] * 1e2 / market.totalShares;
            }
        }
        emit Log("market.totalShares", market.totalShares);
        emit Log("marketId", _marketId);
        emit Log("chance 0", chances[0]);
        emit Log("chance 1", chances[1]);
        return chances;
    }

    function getMarketOutcomePrice(uint256 _marketId, uint256 _outcome) public view returns (uint256) {
        Market storage market = markets[_marketId];
        return market.outcomePrices[_outcome];
    }

    function getMarkets() public view returns (uint256[] memory marketIds) {
        marketIds = new uint256[](marketCount);
        for (uint256 i = 1; i <= marketCount; i++) {
            marketIds[i - 1] = i;
        }

        return marketIds;
    }

    function withdrawFees() public onlyOwner {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getOutcomeCount(Market storage market) internal view returns (uint256) {
        string[] memory outcomeNames;
        (,,,, outcomeNames) = eventOracle.getEventDetails(market.eventId);
        return outcomeNames.length;
    }

    function createMarket(uint256 _eventId) public onlyOwner {
        require(_eventId > 0 && _eventId <= eventOracle.eventCount(), "Invalid event ID");
        require(bluckToken.transferFrom(msg.sender, address(this), 3e18), "BLUCK transfer failed");
        (string memory description, uint256 endTime,, uint256 eventOutcome, string[] memory outcomeNames) =
            eventOracle.getEventDetails(_eventId);

        uint256 _outcomeCount = outcomeNames.length;
        marketCount++;
        Market storage newMarket = markets[marketCount];
        newMarket.eventId = _eventId;
        newMarket.outcomeCount = _outcomeCount;

        // Initialize storage arrays
        newMarket.outcomeLocked = new uint256[](_outcomeCount);
        newMarket.outcomePrices = new uint256[](_outcomeCount);
        newMarket.outcomeShares = new uint256[](_outcomeCount);

        // Set initial price for each outcome to 1e2 / _outcomeCount
        // Also add the initial liquidity
        uint256 initialPrice = 1e2 / _outcomeCount;
        for (uint256 i = 0; i < _outcomeCount; i++) {
            newMarket.outcomePrices[i] = initialPrice;
            newMarket.outcomeLocked[i] = 1e18;
            newMarket.outcomeShares[i] = 1;
        }
        newMarket.totalLocked = 3e18;
        newMarket.totalShares = 3;

        emit MarketCreated(marketCount, _eventId);
    }

    function updateAllOutcomePrices(uint256 _marketId) internal {
        Market storage market = markets[_marketId];
        for (uint256 i = 0; i < market.outcomeCount; i++) {
            if (market.totalLocked > 0) {
                market.outcomePrices[i] = (market.outcomeLocked[i] * 1e2) / market.totalLocked;
            } else {
                market.outcomePrices[i] = 1e2 / market.outcomeCount; // Default to even distribution if no funds are locked
            }
        }
    }

    function swap(uint256 _marketId, uint256 _outcome, uint256 _amountIn) public {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");
        require(_outcome < market.outcomeCount, "Invalid outcome");
        require(_amountIn > 0, "Swap amount must be greater than zero");
        emit Log("before: market.totalShares", market.totalShares);
        emit Log("before: marketId", _marketId);

        uint256 liquidity = market.outcomeLocked[_outcome];
        uint256 amountOut = (_amountIn * liquidity) / (liquidity + _amountIn);

        require(bluckToken.transferFrom(msg.sender, address(this), _amountIn), "BLUCK transfer failed");

        market.outcomeLocked[_outcome] += _amountIn;
        market.totalLocked += _amountIn;

        market.userShares[msg.sender][_outcome] += amountOut;
        market.totalShares += amountOut;
        market.outcomeShares[_outcome] += amountOut;

        emit Swap(_marketId, _outcome, _amountIn, amountOut, msg.sender);
        emit BetPlaced(msg.sender, _marketId, _outcome, amountOut, market.outcomePrices[_outcome]);

        // Update outcome prices using AMM mechanism
        updateAllOutcomePrices(_marketId);
        emit Log("after: market.totalShares", market.totalShares);
        emit Log("after: marketId", _marketId);
    }

    function placeLimitOrder(uint256 _marketId, uint256 _outcome, uint256 _amount, uint256 _price, bool _isBuy)
        public
    {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");
        require(_outcome < market.outcomeCount, "Invalid outcome");
        require(_amount > 0, "Order amount must be greater than zero");
        require(_price > 0 && _price <= 1e2, "Invalid price");

        uint256 remainingAmount = _amount;

        if (_isBuy) {
            require(bluckToken.transferFrom(msg.sender, address(this), _amount * _price), "BLUCK transfer failed");

            for (uint256 i = 0; i < market.orderBooks[_outcome].length && remainingAmount > 0; i++) {
                Order storage order = market.orderBooks[_outcome][i];
                if (!order.isBuy && order.price <= _price && order.share > 0) {
                    uint256 matchAmount = order.share > remainingAmount ? remainingAmount : order.share;
                    uint256 tradeValue = matchAmount * order.price;

                    market.totalLocked += tradeValue;
                    market.outcomeLocked[_outcome] += tradeValue;
                    require(bluckToken.transfer(order.trader, tradeValue), "BLUCK transfer to seller failed");

                    remainingAmount -= matchAmount;
                    order.share -= matchAmount;

                    market.userShares[msg.sender][_outcome] += matchAmount;
                    market.totalShares += matchAmount;
                    market.outcomeShares[_outcome] += matchAmount;

                    emit OrderMatched(_marketId, _outcome, matchAmount, order.price, msg.sender, order.trader);
                    emit BetPlaced(msg.sender, _marketId, _outcome, matchAmount, order.price);
                }
            }

            if (remainingAmount > 0) {
                market.orderBooks[_outcome].push(
                    Order({trader: msg.sender, share: remainingAmount, price: _price, isBuy: true, isLimit: true})
                );

                emit OrderPlaced(_marketId, _outcome, remainingAmount, _price, msg.sender, true);
            }
        } else {
            require(market.userShares[msg.sender][_outcome] >= _amount, "Insufficient shares to sell");

            for (uint256 i = 0; i < market.orderBooks[_outcome].length && remainingAmount > 0; i++) {
                Order storage order = market.orderBooks[_outcome][i];
                if (order.isBuy && order.price >= _price && order.share > 0) {
                    uint256 matchAmount = order.share > remainingAmount ? remainingAmount : order.share;
                    uint256 tradeValue = matchAmount * order.price;

                    market.totalLocked -= tradeValue;
                    market.outcomeLocked[_outcome] -= tradeValue;
                    require(bluckToken.transfer(msg.sender, tradeValue), "BLUCK transfer to seller failed");

                    remainingAmount -= matchAmount;
                    order.share -= matchAmount;

                    market.userShares[msg.sender][_outcome] -= matchAmount;
                    market.totalShares -= matchAmount;
                    market.outcomeShares[_outcome] -= matchAmount;

                    emit OrderMatched(_marketId, _outcome, matchAmount, order.price, order.trader, msg.sender);
                    emit BetPlaced(order.trader, _marketId, _outcome, matchAmount, order.price);
                }
            }

            if (remainingAmount > 0) {
                market.orderBooks[_outcome].push(
                    Order({trader: msg.sender, share: remainingAmount, price: _price, isBuy: false, isLimit: true})
                );

                emit OrderPlaced(_marketId, _outcome, remainingAmount, _price, msg.sender, true);
            }
        }

        // Update all outcome prices after placing or matching orders
        updateAllOutcomePrices(_marketId);
    }

    function settleMarket(uint256 _marketId) public onlyReactive {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");

        (,, bool settled, uint256 outcome,) = eventOracle.getEventDetails(market.eventId);
        require(settled, "Event not settled yet");

        // Liquidate sell orders and refund buy orders
        for (uint256 i = 0; i < market.outcomeCount; i++) {
            Order[] storage orders = market.orderBooks[i];
            for (uint256 j = 0; j < orders.length; j++) {
                Order storage order = orders[j];
                if (order.isBuy) {
                    // Refund buy order
                    require(bluckToken.transfer(order.trader, order.share * order.price), "BLUCK transfer failed");
                } else {
                    // Liquidate sell order at the market price
                    uint256 marketPrice = market.outcomePrices[i]; // Use the market price for liquidation
                    uint256 liquidationValue = order.share * marketPrice;
                    require(bluckToken.transfer(order.trader, liquidationValue), "BLUCK transfer failed");
                }
                emit OrderCancelled(order.trader, _marketId, i, order.share, order.price, order.isBuy);
            }
            delete market.orderBooks[i]; // Clear the order book for the outcome
        }

        market.settled = true;
        market.finalOutcome = outcome;

        emit MarketSettled(_marketId, outcome);
    }

    function claimReward(uint256 _marketId) public {
        Market storage market = markets[_marketId];
        require(market.settled, "Market not settled yet");
        require(!market.rewardClaimed[msg.sender], "Reward already claimed");

        uint256 userShares = market.userShares[msg.sender][market.finalOutcome];
        require(userShares > 0, "No shares for the winning outcome");

        uint256 totalWinningShares = market.outcomeShares[market.finalOutcome];
        uint256 totalPayout = market.totalLocked;
        uint256 fee = (totalPayout * marketFee) / 10000;
        uint256 netPayout = totalPayout - fee;

        // Calculate user reward based on shares
        uint256 reward = (userShares * netPayout) / totalWinningShares;

        market.rewardClaimed[msg.sender] = true;

        require(bluckToken.transfer(msg.sender, reward), "BLUCK transfer failed");

        emit RewardClaimed(msg.sender, _marketId, market.finalOutcome, userShares, reward);
    }

    function cancelOrder(uint256 _marketId, uint256 _outcome, uint256 _orderIndex) public {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");

        Order[] storage orders = market.orderBooks[_outcome];
        require(_orderIndex < orders.length, "Invalid order index");
        Order storage order = orders[_orderIndex];
        require(order.trader == msg.sender, "Not the order owner");

        uint256 refundAmount = order.share * order.price;

        if (order.isBuy) {
            require(bluckToken.transfer(msg.sender, refundAmount), "BLUCK transfer failed");
        } else {
            // Return shares to the seller
            market.userShares[msg.sender][_outcome] += order.share;
            market.totalShares += order.share;
            market.outcomeShares[_outcome] += order.share;
        }

        // Remove the order by swapping it with the last order and then popping the array
        orders[_orderIndex] = orders[orders.length - 1];
        orders.pop();

        emit OrderCancelled(order.trader, _marketId, _outcome, order.share, order.price, order.isBuy);

        // Update outcome prices
        updateAllOutcomePrices(_marketId);
    }
}
