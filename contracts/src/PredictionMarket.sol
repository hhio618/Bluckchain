// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EventOracle.sol";

contract PredictionMarket is Ownable {
    EventOracle public eventOracle;

    struct BetSlip {
        address better;
        uint256 amount;
        uint256 outcome;
    }

    struct Market {
        uint256 eventId;
        uint256 totalBets;
        bool settled;
        mapping(uint256 => uint256) outcomeTotals;
        mapping(address => BetSlip) betSlips;
    }

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    uint256 public marketFee = 30; // 0.3% fee (30 / 10000)
    uint256 public accumulatedFees;

    event MarketCreated(uint256 indexed marketId, uint256 indexed eventId);
    event BetPlaced(uint256 indexed marketId, address indexed better, uint256 outcome, uint256 amount);
    event MarketSettled(uint256 indexed marketId, uint256 outcome);

    constructor(address _eventOracle) Ownable(msg.sender) {
        eventOracle = EventOracle(_eventOracle);
    }

    function createMarket(uint256 _eventId) public onlyOwner {
        require(_eventId > 0 && _eventId <= eventOracle.eventCount(), "Invalid event ID");

        marketCount++;
        Market storage newMarket = markets[marketCount];
        newMarket.eventId = _eventId;

        emit MarketCreated(marketCount, _eventId);
    }

    function placeBet(uint256 _marketId, uint256 _outcome) public payable {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");
        require(bytes(eventOracle.getOutcomeName(market.eventId, _outcome)).length != 0, "Invalid outcome");
        require(msg.value > 0, "Bet amount must be greater than zero");
        require(market.betSlips[msg.sender].amount == 0, "Bet already placed");

        market.totalBets += msg.value;
        market.outcomeTotals[_outcome] += msg.value;
        market.betSlips[msg.sender] = BetSlip(msg.sender, msg.value, _outcome);

        emit BetPlaced(_marketId, msg.sender, _outcome, msg.value);
    }

    function settleMarket(uint256 _marketId) public onlyOwner {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");

        (, , bool settled, uint256 outcome, ) = eventOracle.getEventDetails(market.eventId);
        require(settled, "Event not settled yet");

        market.settled = true;
        emit MarketSettled(_marketId, outcome);

        uint256 totalWinningBets = market.outcomeTotals[outcome];
        if (totalWinningBets > 0) {
            uint256 fee = (market.totalBets * marketFee) / 10000;
            uint256 totalPayout = market.totalBets - fee;

            accumulatedFees += fee;

            for (uint256 i = 0; i < marketCount; i++) {
                BetSlip storage betSlip = market.betSlips[msg.sender];
                if (betSlip.outcome == outcome) {
                    uint256 reward = (betSlip.amount * totalPayout) / totalWinningBets;
                    (bool success, ) = betSlip.better.call{value: reward}("");
                    require(success, "Transfer to winner failed");
                }
            }
        }
    }

    function withdrawFees() public onlyOwner {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getMarketTotalBets(uint256 _marketId) public view returns (uint256) {
        return markets[_marketId].totalBets;
    }

    function getMarketOutcomeTotals(uint256 _marketId, uint256 _outcome) public view returns (uint256) {
        return markets[_marketId].outcomeTotals[_outcome];
    }

    function getBetSlip(uint256 _marketId, address _better) public view returns (uint256 amount, uint256 outcome) {
        BetSlip storage betSlip = markets[_marketId].betSlips[_better];
        return (betSlip.amount, betSlip.outcome);
    }
}
