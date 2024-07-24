// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EventOracle.sol";

contract PredictionMarket is Ownable {
    EventOracle public eventOracle;
    address private callback_sender;

    struct BetSlip {
        uint256 marketId;
        address better;
        uint256 amount;
        uint256 outcome;
        uint256 winningPrize;
        bool settled;
    }

    struct Market {
        uint256 eventId;
        uint256 totalBets;
        bool settled;
        mapping(uint256 => uint256) outcomeTotals;
        mapping(address => BetSlip) betSlips;
        mapping(address => bool) uniqueBetters;
        address[] betters;
        mapping(address => uint256) totalUserBets;
        mapping(address => uint256) totalUserPrizes;
    }

    // Stats for all users across all the markets
    mapping(address => bool) public uniqueBetters;
    address[] public betters;
    mapping(address => uint256) public totalUserBets;
    mapping(address => uint256) public totalUserPrizes;

    // Market
    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    uint256 public marketFee = 30; // 0.3% fee (30 / 10000)
    uint256 public accumulatedFees;

    event MarketCreated(uint256 indexed marketId, uint256 indexed eventId);
    event BetPlaced(uint256 indexed marketId, address indexed better, uint256 outcome, uint256 amount);
    event MarketSettled(uint256 indexed marketId, uint256 outcome);
    event FeesWithdrawn(uint256 amount);

    constructor(address _eventOracle, address _callback_sender) Ownable(msg.sender) {
        eventOracle = EventOracle(_eventOracle);
        callback_sender = _callback_sender;
    }

    modifier onlyReactive() {
        if (callback_sender != address(0)) {
            require(msg.sender == callback_sender, "Unauthorized");
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
        market.betSlips[msg.sender] = BetSlip(_marketId, msg.sender, msg.value, _outcome, 0, false);
        if (!market.uniqueBetters[msg.sender]) {
            market.uniqueBetters[msg.sender] = true;
            market.betters.push(msg.sender);
        }
        market.totalUserBets[msg.sender] += msg.value; // Update total bets for this user
        totalUserBets[msg.sender] += msg.value;

        if (!uniqueBetters[msg.sender]) {
            uniqueBetters[msg.sender] = true;
            betters.push(msg.sender);
        }

        emit BetPlaced(_marketId, msg.sender, _outcome, msg.value);
    }

    function settleMarket(uint256 _marketId) public onlyReactive {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");

        (,, bool settled, uint256 outcome,) = eventOracle.getEventDetails(market.eventId);
        require(settled, "Event not settled yet");

        market.settled = true;
        emit MarketSettled(_marketId, outcome);

        uint256 totalWinningBets = market.outcomeTotals[outcome];
        if (totalWinningBets > 0) {
            uint256 fee = (market.totalBets * marketFee) / 10000;
            uint256 totalPayout = market.totalBets - fee;

            accumulatedFees += fee;

            for (uint256 i = 0; i < market.betters.length; i++) {
                address better = market.betters[i];
                BetSlip storage betSlip = market.betSlips[better];
                if (betSlip.outcome == outcome) {
                    betSlip.winningPrize = (betSlip.amount * totalPayout) / totalWinningBets;
                    betSlip.settled = true;
                    market.totalUserPrizes[better] += betSlip.winningPrize; // Update total prizes for this user
                    totalUserPrizes[betSlip.better] += betSlip.winningPrize;
                    (bool success,) = betSlip.better.call{value: betSlip.winningPrize}("");
                    require(success, "Transfer to winner failed");
                }
            }
        }
    }

    function withdrawFees() public onlyOwner {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getMarketDetails(uint256 _marketId)
        public
        view
        returns (
            uint256 eventId,
            uint256 totalBets,
            bool marketSettled,
            uint256 outcome,
            string memory description,
            uint256 endTime,
            bool eventSettled,
            uint256 eventOutcome,
            string[] memory outcomeNames
        )
    {
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

    function getMarkets(bool _settled)
        public
        view
        returns (
            uint256[] memory marketIds,
            uint256[] memory eventIds,
            uint256[] memory totalBets,
            bool[] memory marketSettled,
            uint256[] memory outcomes
        )
    {
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

    function getUserBetSlips(address user)
        public
        view
        returns (
            uint256[] memory marketIds,
            uint256[] memory eventIds,
            uint256[] memory totalBets,
            bool[] memory marketSettled,
            BetSlip[] memory userBetSlips
        )
    {
        uint256 count = 0;

        // Count the number of bet slips for the user
        for (uint256 i = 1; i <= marketCount; i++) {
            if (markets[i].betSlips[user].amount > 0) {
                count++;
            }
        }

        // Initialize arrays to hold the market details and bet slips
        marketIds = new uint256[](count);
        eventIds = new uint256[](count);
        totalBets = new uint256[](count);
        marketSettled = new bool[](count);
        userBetSlips = new BetSlip[](count);

        uint256 index = 0;

        // Collect the market details and bet slips
        for (uint256 i = 1; i <= marketCount; i++) {
            if (markets[i].betSlips[user].amount > 0) {
                Market storage market = markets[i];
                marketIds[index] = i;
                eventIds[index] = market.eventId;
                totalBets[index] = market.totalBets;
                marketSettled[index] = market.settled;
                userBetSlips[index] = market.betSlips[user];
                index++;
            }
        }

        return (marketIds, eventIds, totalBets, marketSettled, userBetSlips);
    }

    function getUserRankings() public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 userCount = betters.length;

        address[] memory users = new address[](userCount);
        uint256[] memory totalBets = new uint256[](userCount);
        uint256[] memory totalPrizes = new uint256[](userCount);

        for (uint256 i = 0; i < userCount; i++) {
            users[i] = betters[i];
            totalBets[i] = totalUserBets[betters[i]];
            totalPrizes[i] = totalUserPrizes[betters[i]];
        }

        // Sort users by totalBets in descending order
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - 1 - i; j++) {
                if (totalBets[j] < totalBets[j + 1]) {
                    // Swap users
                    (users[j], users[j + 1]) = (users[j + 1], users[j]);
                    // Swap totalBets
                    (totalBets[j], totalBets[j + 1]) = (totalBets[j + 1], totalBets[j]);
                    // Swap totalPrizes
                    (totalPrizes[j], totalPrizes[j + 1]) = (totalPrizes[j + 1], totalPrizes[j]);
                }
            }
        }

        return (users, totalBets, totalPrizes);
    }

    function getTopBets(uint256 _marketId) public view returns (BetSlip[] memory) {
        Market storage market = markets[_marketId];
        uint256 count = market.betters.length;

        // Initialize an array to hold the bet slips
        BetSlip[] memory topBets = new BetSlip[](count);

        // Collect the bet slips
        for (uint256 i = 0; i < count; i++) {
            address better = market.betters[i];
            topBets[i] = market.betSlips[better];
        }

        // Sort the bet slips by amount in descending order
        for (uint256 i = 0; i < count - 1; i++) {
            for (uint256 j = 0; j < count - 1 - i; j++) {
                if (topBets[j].amount < topBets[j + 1].amount) {
                    BetSlip memory temp = topBets[j];
                    topBets[j] = topBets[j + 1];
                    topBets[j + 1] = temp;
                }
            }
        }

        return topBets;
    }

    function getTopUsers() public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 userCount = betters.length;

        address[] memory users = new address[](userCount);
        uint256[] memory totalBets = new uint256[](userCount);
        uint256[] memory totalPrizes = new uint256[](userCount);

        for (uint256 i = 0; i < userCount; i++) {
            users[i] = betters[i];
            totalBets[i] = totalUserBets[betters[i]];
            totalPrizes[i] = totalUserPrizes[betters[i]];
        }

        // Sort users by totalPrizes in descending order
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - 1 - i; j++) {
                if (totalPrizes[j] < totalPrizes[j + 1]) {
                    // Swap users
                    (users[j], users[j + 1]) = (users[j + 1], users[j]);
                    // Swap totalBets
                    (totalBets[j], totalBets[j + 1]) = (totalBets[j + 1], totalBets[j]);
                    // Swap totalPrizes
                    (totalPrizes[j], totalPrizes[j + 1]) = (totalPrizes[j + 1], totalPrizes[j]);
                }
            }
        }

        return (users, totalBets, totalPrizes);
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
