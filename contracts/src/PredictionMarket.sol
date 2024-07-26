// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EventOracle.sol";

contract PredictionMarket is Ownable {
    EventOracle public eventOracle;
    IERC20 public bluckToken;
    address private callback_sender;

    struct BetSlip {
        uint256 marketId;
        address better;
        uint256 amount;
        uint256 outcome;
        uint256 winningPrize;
        bool settled;
    }

    struct Order {
        address trader;
        uint256 amount;
        uint256 price;
        bool isBuy; // true for buy order, false for sell order
        bool isLimit; // true for limit order, false for market order
    }

    struct Market {
        uint256 eventId;
        uint256 totalBets;
        bool settled;
        mapping(uint256 => uint256) outcomeTotals;
        mapping(address => mapping(uint256 => BetSlip)) betSlips;
        mapping(address => bool) uniqueBetters;
        address[] betters;
        mapping(uint256 => Order[]) orderBooks; // Order books for each outcome
        mapping(uint256 => uint256) outcomePrices; // New mapping for outcome prices
    }

    mapping(address => bool) public uniqueBetters;
    address[] public betters;

    mapping(uint256 => Market) public markets;
    uint256 public marketCount;
    uint256 public marketFee = 30; // 0.3% fee (30 / 10000)
    uint256 public accumulatedFees;

    mapping(address => uint256) public userVolumes;
    mapping(address => int256) public userProfits;

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
    event BetSettled(
        address indexed user,
        uint256 indexed marketId,
        uint256 outcome,
        uint256 amount,
        uint256 winningPrize,
        int256 profit
    );

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
            string[] memory descriptions,
            string[][] memory outcomes,
            uint256[] memory totalBets,
            uint256[] memory totalUniqueUsers
        )
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= marketCount; i++) {
            if (markets[i].settled == _settled) {
                count++;
            }
        }

        marketIds = new uint256[](count);
        descriptions = new string[](count);
        outcomes = new string[][](count);
        totalBets = new uint256[](count);
        totalUniqueUsers = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = 1; i <= marketCount; i++) {
            if (markets[i].settled == _settled) {
                Market storage market = markets[i];
                string memory description;
                string[] memory outcomeNames;
                (description,,,, outcomeNames) = eventOracle.getEventDetails(market.eventId);

                marketIds[index] = i;
                descriptions[index] = description;
                outcomes[index] = outcomeNames;
                totalBets[index] = market.totalBets;
                totalUniqueUsers[index] = market.betters.length;

                index++;
            }
        }

        return (marketIds, descriptions, outcomes, totalBets, totalUniqueUsers);
    }

    function updateOutcomePrices(uint256 _marketId) internal {
        Market storage market = markets[_marketId];
        for (uint256 i = 0; i < getOutcomeCount(market); i++) {
            if (market.totalBets > 0) {
                market.outcomePrices[i] = (market.outcomeTotals[i] * 1e18) / market.totalBets;
            } else {
                market.outcomePrices[i] = 1e18; // Default to 1 if no bets
            }
        }
    }

    function getOrderBook(uint256 _marketId, uint256 _outcome)
        public
        view
        returns (
            address[] memory users,
            uint256[] memory amounts,
            uint256[] memory prices,
            bool[] memory isBuys,
            bool[] memory isLimits
        )
    {
        Order[] storage orders = markets[_marketId].orderBooks[_outcome];
        uint256 orderCount = orders.length;

        users = new address[](orderCount);
        amounts = new uint256[](orderCount);
        prices = new uint256[](orderCount);
        isBuys = new bool[](orderCount);
        isLimits = new bool[](orderCount);

        for (uint256 i = 0; i < orderCount; i++) {
            Order storage order = orders[i];
            users[i] = order.trader;
            amounts[i] = order.amount;
            prices[i] = order.price;
            isBuys[i] = order.isBuy;
            isLimits[i] = order.isLimit;
        }
    }

    function createMarket(uint256 _eventId) public onlyOwner {
        require(_eventId > 0 && _eventId <= eventOracle.eventCount(), "Invalid event ID");

        marketCount++;
        Market storage newMarket = markets[marketCount];
        newMarket.eventId = _eventId;

        emit MarketCreated(marketCount, _eventId);
    }

    function getVolume(address _user) public view returns (uint256) {
        return userVolumes[_user];
    }

    function getTopUsersByVolume() public view returns (address[] memory users, uint256[] memory volumes) {
        uint256 userCount = betters.length;

        // Initialize arrays for top 20 users
        users = new address[](userCount > 20 ? 20 : userCount);
        volumes = new uint256[](userCount > 20 ? 20 : userCount);

        // Create an array to hold all user volumes
        uint256[] memory userVolumesArray = new uint256[](userCount);
        address[] memory usersArray = new address[](userCount);

        // Populate the userVolumesArray with the volumes
        for (uint256 i = 0; i < userCount; i++) {
            usersArray[i] = betters[i];
            userVolumesArray[i] = userVolumes[betters[i]];
        }

        // Sort usersArray by volume in descending order
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - 1 - i; j++) {
                if (userVolumesArray[j] < userVolumesArray[j + 1]) {
                    // Swap usersArray
                    address tempUser = usersArray[j];
                    usersArray[j] = usersArray[j + 1];
                    usersArray[j + 1] = tempUser;
                    // Swap volumes
                    uint256 tempVolume = userVolumesArray[j];
                    userVolumesArray[j] = userVolumesArray[j + 1];
                    userVolumesArray[j + 1] = tempVolume;
                }
            }
        }

        // Populate the top 20 users and their volumes
        for (uint256 i = 0; i < (userCount > 20 ? 20 : userCount); i++) {
            users[i] = usersArray[i];
            volumes[i] = userVolumesArray[i];
        }

        return (users, volumes);
    }

    function placeLimitOrder(uint256 _marketId, uint256 _outcome, uint256 _amount, uint256 _price, bool _isBuy)
        public
    {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");
        require(bytes(eventOracle.getOutcomeName(market.eventId, _outcome)).length != 0, "Invalid outcome");
        require(_amount > 0, "Order amount must be greater than zero");

        if (_isBuy) {
            require(bluckToken.transferFrom(msg.sender, address(this), _amount * _price), "BLUCK transfer failed");
        } else {
            require(market.betSlips[msg.sender][_outcome].amount >= _amount, "Insufficient amount to sell");
            market.betSlips[msg.sender][_outcome].amount -= _amount;
        }

        // Update user volume
        userVolumes[msg.sender] += _amount;

        market.orderBooks[_outcome].push(
            Order({trader: msg.sender, amount: _amount, price: _price, isBuy: _isBuy, isLimit: true})
        );

        updateOutcomePrices(_marketId); // Update prices after placing an order

        emit OrderPlaced(_marketId, _outcome, _amount, _price, msg.sender, true);
    }

    function placeMarketOrder(uint256 _marketId, uint256 _outcome, uint256 _amount, bool _isBuy) public {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");
        require(bytes(eventOracle.getOutcomeName(market.eventId, _outcome)).length != 0, "Invalid outcome");
        require(_amount > 0, "Order amount must be greater than zero");

        uint256 remainingAmount = _amount;

        if (_isBuy) {
            uint256 totalCost = 0;
            for (uint256 i = 0; i < market.orderBooks[_outcome].length && remainingAmount > 0; i++) {
                Order storage order = market.orderBooks[_outcome][i];
                if (!order.isBuy && order.amount > 0) {
                    uint256 matchAmount = (order.amount > remainingAmount) ? remainingAmount : order.amount;
                    totalCost += matchAmount * order.price;
                    order.amount -= matchAmount;
                    remainingAmount -= matchAmount;
                    require(
                        bluckToken.transfer(order.trader, matchAmount * order.price), "BLUCK transfer to seller failed"
                    );
                    emit OrderMatched(_marketId, _outcome, matchAmount, order.price, msg.sender, order.trader);
                }
            }
            require(bluckToken.transferFrom(msg.sender, address(this), totalCost), "BLUCK transfer from buyer failed");

            // Update user volume
            userVolumes[msg.sender] += (_amount - remainingAmount);
        } else {
            for (uint256 i = 0; i < market.orderBooks[_outcome].length && remainingAmount > 0; i++) {
                Order storage order = market.orderBooks[_outcome][i];
                if (order.isBuy && order.amount > 0) {
                    uint256 matchAmount = (order.amount > remainingAmount) ? remainingAmount : order.amount;
                    uint256 totalCost = matchAmount * order.price;
                    require(market.betSlips[msg.sender][_outcome].amount >= matchAmount, "Insufficient amount to sell");
                    market.betSlips[msg.sender][_outcome].amount -= matchAmount;
                    market.totalBets -= matchAmount;
                    order.amount -= matchAmount;
                    remainingAmount -= matchAmount;
                    require(bluckToken.transfer(msg.sender, totalCost), "BLUCK transfer to seller failed");
                    emit OrderMatched(_marketId, _outcome, matchAmount, order.price, order.trader, msg.sender);
                }
            }

            require(remainingAmount == 0, "Insufficient buy orders to match");

            // Update user volume
            userVolumes[msg.sender] += (_amount - remainingAmount);
        }

        if (remainingAmount > 0) {
            market.orderBooks[_outcome].push(
                Order({trader: msg.sender, amount: remainingAmount, price: 0, isBuy: _isBuy, isLimit: false})
            );

            emit OrderPlaced(_marketId, _outcome, remainingAmount, 0, msg.sender, false);
        }

        updateOutcomePrices(_marketId); // Update prices after placing an order
    }

    function cancelOrder(uint256 _marketId, uint256 _outcome, uint256 _orderIndex) public {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");

        Order[] storage orders = market.orderBooks[_outcome];
        require(_orderIndex < orders.length, "Invalid order index");
        Order storage order = orders[_orderIndex];
        require(order.trader == msg.sender, "Not the order owner");
        require(order.isLimit, "Cannot cancel market order");

        if (order.isBuy) {
            require(bluckToken.transfer(order.trader, order.amount * order.price), "BLUCK transfer failed");
        } else {
            market.betSlips[order.trader][_outcome].amount += order.amount;
        }

        // Emit the OrderCancelled event
        emit OrderCancelled(order.trader, _marketId, _outcome, order.amount, order.price, order.isBuy);

        // Remove the order from the order book
        for (uint256 i = _orderIndex; i < orders.length - 1; i++) {
            orders[i] = orders[i + 1];
        }
        orders.pop();
    }

    function settleMarket(uint256 _marketId) public onlyReactive {
        Market storage market = markets[_marketId];
        require(!market.settled, "Market already settled");

        (,, bool settled, uint256 outcome,) = eventOracle.getEventDetails(market.eventId);
        require(settled, "Event not settled yet");

        // Cancel and refund current orders
        for (uint256 i = 0; i < getOutcomeCount(market); i++) {
            Order[] storage orders = market.orderBooks[i];
            uint256 remainingAmount;
            for (uint256 j = 0; j < orders.length; j++) {
                Order storage order = orders[j];
                remainingAmount = order.amount;
                if (order.isBuy) {
                    require(bluckToken.transfer(order.trader, remainingAmount * order.price), "BLUCK transfer failed");
                } else {
                    market.betSlips[order.trader][i].amount += remainingAmount;
                }
                emit OrderCancelled(order.trader, _marketId, i, remainingAmount, order.price, order.isBuy);
            }
            delete market.orderBooks[i]; // Clear the order book for the outcome
        }

        uint256 totalWinningBets = market.outcomeTotals[outcome];
        if (totalWinningBets > 0) {
            uint256 fee = (market.totalBets * marketFee) / 10000;
            uint256 totalPayout = market.totalBets - fee;

            market.settled = true;
            accumulatedFees += fee;

            for (uint256 i = 0; i < market.betters.length; i++) {
                address better = market.betters[i];
                for (uint256 j = 0; j < getOutcomeCount(market); j++) {
                    BetSlip storage betSlip = market.betSlips[better][j];
                    if (betSlip.outcome == outcome) {
                        betSlip.winningPrize = (betSlip.amount * totalPayout) / totalWinningBets;
                        userProfits[betSlip.better] += int256(betSlip.winningPrize) - int256(betSlip.amount);
                        require(bluckToken.transfer(betSlip.better, betSlip.winningPrize), "BLUCK transfer failed");

                        // Emit the BetSettled event
                        emit BetSettled(
                            betSlip.better,
                            _marketId,
                            betSlip.outcome,
                            betSlip.amount,
                            betSlip.winningPrize,
                            int256(betSlip.winningPrize) - int256(betSlip.amount)
                        );
                    }
                    betSlip.settled = true;
                }
            }
        }
        emit MarketSettled(_marketId, outcome);
    }

    function withdrawFees() public onlyOwner {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getSettledMarketOutcome(uint256 _marketId) public view returns (uint256) {
        Market storage market = markets[_marketId];
        require(market.settled, "Market is not settled yet");

        (,, bool settled, uint256 outcome,) = eventOracle.getEventDetails(market.eventId);
        require(settled, "Event not settled yet");

        return outcome;
    }

    function getUserPositions(address _user)
        public
        view
        returns (
            uint256[] memory marketIds,
            uint256[] memory outcomes,
            uint256[] memory totalBets,
            uint256[] memory winningPrizes,
            int256[] memory winningProfits
        )
    {
        uint256 positionCount = 0;

        // First pass to count the number of positions
        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            for (uint256 j = 0; j < getOutcomeCount(market); j++) {
                if (market.betSlips[_user][j].amount > 0) {
                    positionCount++;
                }
            }
        }

        marketIds = new uint256[](positionCount);
        outcomes = new uint256[](positionCount);
        totalBets = new uint256[](positionCount);
        winningPrizes = new uint256[](positionCount);
        winningProfits = new int256[](positionCount);

        uint256 index = 0;

        // Second pass to populate the arrays
        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            for (uint256 j = 0; j < getOutcomeCount(market); j++) {
                if (market.betSlips[_user][j].amount > 0) {
                    marketIds[index] = i;
                    outcomes[index] = j;
                    totalBets[index] = market.betSlips[_user][j].amount;
                    winningPrizes[index] = calculateUserWinningPrize(i, j, _user);

                    // Calculate the winningProfit
                    winningProfits[index] = int256(winningPrizes[index]) - int256(market.betSlips[_user][j].amount);
                    index++;
                }
            }
        }

        return (marketIds, outcomes, totalBets, winningPrizes, winningProfits);
    }

    function calculateUserWinningPrize(uint256 _marketId, uint256 _outcome, address _user)
        internal
        view
        returns (uint256)
    {
        Market storage market = markets[_marketId];
        uint256 userBetAmount = market.betSlips[_user][_outcome].amount;
        uint256 price = market.outcomePrices[_outcome];
        uint256 fee = (userBetAmount * marketFee) / 10000;
        uint256 netAmount = userBetAmount - fee;

        return (netAmount * 1e18) / price;
    }

    function calculateMarketOdds(uint256 _marketId) public view returns (uint256[] memory) {
        Market storage market = markets[_marketId];
        string[] memory outcomeNames;
        (,,,, outcomeNames) = eventOracle.getEventDetails(market.eventId);
        uint256 outcomesCount = outcomeNames.length;

        uint256[] memory odds = new uint256[](outcomesCount);
        uint256 feeAdjustedTotalBets = market.totalBets - (market.totalBets * marketFee / 10000);

        for (uint256 i = 0; i < outcomesCount; i++) {
            if (market.outcomeTotals[i] > 0) {
                odds[i] = (feeAdjustedTotalBets * 100) / market.outcomeTotals[i];
            } else {
                odds[i] = 0;
            }
        }

        return odds;
    }

    function getUserTotalWinningProfit(address _user) public view returns (int256) {
        int256 totalWinningProfit = 0;

        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            for (uint256 j = 0; j < getOutcomeCount(market); j++) {
                if (market.betSlips[_user][j].amount > 0) {
                    totalWinningProfit +=
                        int256(calculateUserWinningPrize(i, j, _user)) - int256(market.betSlips[_user][j].amount);
                }
            }
        }

        return totalWinningProfit;
    }

    function getUserBetHistory(address _user)
        public
        view
        returns (
            uint256[] memory marketIds,
            uint256[] memory outcomes,
            uint256[] memory lastPrices,
            uint256[] memory amounts,
            int256[] memory profits,
            uint256[] memory marketOutcomes,
            uint256[] memory userOutcomes
        )
    {
        uint256 historyCount = 0;

        // First pass to count the number of settled markets with user bets
        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            if (market.settled) {
                for (uint256 outcome = 0; outcome < getOutcomeCount(market); outcome++) {
                    if (market.betSlips[_user][outcome].amount > 0) {
                        historyCount++;
                    }
                }
            }
        }

        marketIds = new uint256[](historyCount);
        outcomes = new uint256[](historyCount);
        lastPrices = new uint256[](historyCount);
        amounts = new uint256[](historyCount);
        profits = new int256[](historyCount);
        marketOutcomes = new uint256[](historyCount);
        userOutcomes = new uint256[](historyCount);

        uint256 index = 0;

        // Second pass to populate the arrays
        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            if (market.settled) {
                for (uint256 outcome = 0; outcome < getOutcomeCount(market); outcome++) {
                    BetSlip storage betSlip = market.betSlips[_user][outcome];
                    if (betSlip.amount > 0) {
                        marketIds[index] = i;
                        outcomes[index] = outcome;
                        lastPrices[index] = betSlip.winningPrize; // Assuming this is the correct last price
                        amounts[index] = betSlip.amount;
                        profits[index] = int256(betSlip.winningPrize) - int256(betSlip.amount);
                        marketOutcomes[index] = outcome; // Assuming this is the correct market outcome
                        userOutcomes[index] = betSlip.outcome;
                        index++;
                    }
                }
            }
        }

        return (marketIds, outcomes, lastPrices, amounts, profits, marketOutcomes, userOutcomes);
    }

    function getTopUsersByProfit() public view returns (address[] memory users, int256[] memory profits) {
        uint256 userCount = betters.length;

        // Initialize arrays for top 20 users
        users = new address[](userCount > 20 ? 20 : userCount);
        profits = new int256[](userCount > 20 ? 20 : userCount);

        // Create an array to hold all user profits
        int256[] memory userProfitsArray = new int256[](userCount);
        address[] memory usersArray = new address[](userCount);

        // Populate the userProfitsArray with the profits
        for (uint256 i = 0; i < userCount; i++) {
            usersArray[i] = betters[i];
            userProfitsArray[i] = userProfits[betters[i]];
        }

        // Sort usersArray by profit in descending order
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - 1 - i; j++) {
                if (userProfitsArray[j] < userProfitsArray[j + 1]) {
                    // Swap usersArray
                    address tempUser = usersArray[j];
                    usersArray[j] = usersArray[j + 1];
                    usersArray[j + 1] = tempUser;
                    // Swap profits
                    int256 tempProfit = userProfitsArray[j];
                    userProfitsArray[j] = userProfitsArray[j + 1];
                    userProfitsArray[j + 1] = tempProfit;
                }
            }
        }

        // Populate the top 20 users and their profits
        for (uint256 i = 0; i < (userCount > 20 ? 20 : userCount); i++) {
            users[i] = usersArray[i];
            profits[i] = userProfitsArray[i];
        }

        return (users, profits);
    }

    function getOutcomeCount(Market storage market) internal view returns (uint256) {
        string[] memory outcomeNames;
        (,,,, outcomeNames) = eventOracle.getEventDetails(market.eventId);
        return outcomeNames.length;
    }

    function getMarketOrders(uint256 _marketId, uint256 _outcome)
        public
        view
        returns (address[] memory users, uint256[] memory amounts, bool[] memory isBuys, bool[] memory isLimits)
    {
        Market storage market = markets[_marketId];
        Order[] storage orders = market.orderBooks[_outcome];

        uint256 activityCount = orders.length > 20 ? 20 : orders.length;

        users = new address[](activityCount);
        amounts = new uint256[](activityCount);
        isBuys = new bool[](activityCount);
        isLimits = new bool[](activityCount);

        uint256 startIndex = orders.length > 20 ? orders.length - 20 : 0;
        for (uint256 i = 0; i < activityCount; i++) {
            uint256 orderIndex = startIndex + i;
            Order storage order = orders[orderIndex];
            users[i] = order.trader;
            amounts[i] = order.amount;
            isBuys[i] = order.isBuy;
            isLimits[i] = order.isLimit;
        }

        return (users, amounts, isBuys, isLimits);
    }

    function getTopHolders(uint256 _marketId, uint256 _outcome)
        public
        view
        returns (address[] memory holders, uint256[] memory amounts)
    {
        Market storage market = markets[_marketId];
        uint256 holderCount = market.betters.length;
        uint256 maxCount = holderCount > 20 ? 20 : holderCount;

        holders = new address[](maxCount);
        amounts = new uint256[](maxCount);

        for (uint256 i = 0; i < maxCount; i++) {
            address better = market.betters[i];
            amounts[i] = market.betSlips[better][_outcome].amount;
        }

        // Sort holders by amounts in descending order
        for (uint256 i = 0; i < maxCount - 1; i++) {
            for (uint256 j = 0; j < maxCount - 1 - i; j++) {
                if (amounts[j] < amounts[j + 1]) {
                    // Swap holders
                    address tempHolder = holders[j];
                    holders[j] = holders[j + 1];
                    holders[j + 1] = tempHolder;
                    // Swap amounts
                    uint256 tempAmount = amounts[j];
                    amounts[j] = amounts[j + 1];
                    amounts[j + 1] = tempAmount;
                }
            }
        }

        return (holders, amounts);
    }

    function getUserOrders(address _user)
        public
        view
        returns (
            uint256[] memory marketIds,
            uint256[] memory outcomes,
            uint256[] memory amounts,
            bool[] memory isBuys,
            bool[] memory isLimits
        )
    {
        uint256 activityCount = 0;

        // First pass to count the number of activities
        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            for (uint256 outcome = 0; outcome < getOutcomeCount(market); outcome++) {
                Order[] storage orders = market.orderBooks[outcome];
                for (uint256 j = 0; j < orders.length; j++) {
                    if (orders[j].trader == _user) {
                        activityCount++;
                    }
                }
            }
        }

        marketIds = new uint256[](activityCount);
        outcomes = new uint256[](activityCount);
        amounts = new uint256[](activityCount);
        isBuys = new bool[](activityCount);
        isLimits = new bool[](activityCount);

        uint256 index = 0;

        // Second pass to populate the arrays
        for (uint256 i = 1; i <= marketCount; i++) {
            Market storage market = markets[i];
            for (uint256 outcome = 0; outcome < getOutcomeCount(market); outcome++) {
                Order[] storage orders = market.orderBooks[outcome];
                for (uint256 j = 0; j < orders.length; j++) {
                    if (orders[j].trader == _user) {
                        marketIds[index] = i;
                        outcomes[index] = outcome;
                        amounts[index] = orders[j].amount;
                        isBuys[index] = orders[j].isBuy;
                        isLimits[index] = orders[j].isLimit;
                        index++;
                    }
                }
            }
        }

        return (marketIds, outcomes, amounts, isBuys, isLimits);
    }
}
