// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EventOracle.sol";

contract PredictionMarket is Ownable {
    EventOracle public eventOracle;
    address private callback_sender;

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

    constructor(address _eventOracle, address _callback_sender) Ownable(msg.sender) {
        eventOracle = EventOracle(_eventOracle);
      callback_sender = _callback_sender;
    }

    modifier onlyReactive() {
        if (callback_sender != address(0)) {
            require(msg.sender == callback_sender, 'Unauthorized');
        }
        _;
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

    function settleMarket(uint256 _marketId) public onlyReactive {
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


    function getMarketDetails(uint256 _marketId) public view returns (
        uint256 eventId,
        uint256 totalBets,
        bool marketSettled,
        uint256 outcome,
        string memory description,
        uint256 endTime,
        bool eventSettled,
        uint256 eventOutcome,
        string[] memory outcomeNames
    ) {
        Market storage market = markets[_marketId];
        (description, endTime, eventSettled, eventOutcome, outcomeNames) = eventOracle.getEventDetails(market.eventId);

        return (
            market.eventId,
            market.totalBets,
            market.settled,
            eventOutcome,
            description,
            endTime,
            eventSettled,
            eventOutcome,
            outcomeNames
        );
    }

    function getMarkets(bool _settled) public view returns (
        uint256[] memory marketIds,
        uint256[] memory eventIds,
        uint256[] memory totalBets,
        bool[] memory marketSettled,
        uint256[] memory outcomes
    ) {
        uint256 count = 0;
        for (uint256 i = 1; i <= marketCount; i++) {
            if (markets[i].settled == _settled) {
                count++;
            }
        }

        marketIds = new uint256[](count);
        eventIds = new uint256[](count);
        totalBets = new uint256[](count);
        marketSettled = new bool[](count);
        outcomes = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = 1; i <= marketCount; i++) {
            if (markets[i].settled == _settled) {
                marketIds[index] = i;
                eventIds[index] = markets[i].eventId;
                totalBets[index] = markets[i].totalBets;
                marketSettled[index] = markets[i].settled;
                outcomes[index] = markets[i].outcomeTotals[markets[i].eventId];
                index++;
            }
        }

        return (marketIds, eventIds, totalBets, marketSettled, outcomes);
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
