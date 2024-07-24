// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PredictionMarket.sol";
import "../src/EventOracle.sol";

contract PredictionMarketTest is Test {
    PredictionMarket predictionMarket;
    EventOracle eventOracle;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);
    uint256 marketId = 1;
    uint256 eventId = 1;

    function setUp() public {
        vm.startPrank(owner);
        eventOracle = new EventOracle();
        predictionMarket = new PredictionMarket(address(eventOracle), address(0));
        vm.stopPrank();
    }

    function testCreateEventAndMarket() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        assertEq(eventOracle.eventCount(), 1);

        predictionMarket.createMarket(1);
        assertEq(predictionMarket.marketCount(), 1);
        vm.stopPrank();
    }

    function testPlaceBet() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.deal(address(1), 1 ether);
        vm.startPrank(address(1));
        predictionMarket.placeBet{value: 1 ether}(1, 0);
        vm.stopPrank();

        // Check if the bet was placed correctly
        uint256 totalBets = predictionMarket.getMarketTotalBets(1);
        assertEq(totalBets, 1 ether);

        uint256 outcomeTotal = predictionMarket.getMarketOutcomeTotals(1, 0);
        assertEq(outcomeTotal, 1 ether);

        (uint256 amount, uint256 outcome) = predictionMarket.getBetSlip(1, address(1));
        assertEq(amount, 1 ether);
        assertEq(outcome, 0);
    }

    function testSettleMarket() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.deal(address(1), 1 ether);
        vm.deal(address(2), 1 ether);

        vm.startPrank(address(1));
        predictionMarket.placeBet{value: 1 ether}(1, 0);
        vm.stopPrank();

        vm.startPrank(address(2));
        predictionMarket.placeBet{value: 1 ether}(1, 1);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);
        // Settle the event in the EventOracle
        eventOracle.settleEvent(1, 0);
        vm.stopPrank();

        // Settle the market in PredictionMarket
        predictionMarket.settleMarket(1);

        // Check balances
        uint256 fee = (2 ether * 30) / 10000; // 0.3% fee
        assertEq(predictionMarket.accumulatedFees(), fee); // check accumulated fees
        assertEq(address(1).balance, (2 ether * 9970) / 10000); // winning bet minus fee
    }

    function testWithdrawFees() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.deal(address(1), 1 ether);
        vm.deal(address(2), 1 ether);

        vm.startPrank(address(1));
        predictionMarket.placeBet{value: 1 ether}(1, 0);
        vm.stopPrank();

        vm.startPrank(address(2));
        predictionMarket.placeBet{value: 1 ether}(1, 1);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);
        // Settle the event in the EventOracle
        eventOracle.settleEvent(1, 0);
        vm.stopPrank();

        // Settle the market in PredictionMarket
        predictionMarket.settleMarket(1);

        vm.startPrank(owner);
        // Withdraw the fees
        uint256 initialBalance = owner.balance;
        predictionMarket.withdrawFees();
        vm.stopPrank();
        uint256 fee = (2 ether * 30) / 10000; // 0.3% fee
        assertEq(owner.balance, initialBalance + fee); // check owner's balance after withdrawal
    }

    function testSettleMarketInvalidOutcome() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.deal(address(1), 1 ether);

        vm.startPrank(address(1));
        predictionMarket.placeBet{value: 1 ether}(1, 0);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);
        // Try to settle the event in the EventOracle with an invalid outcome
        vm.expectRevert("Invalid outcome");
        eventOracle.settleEvent(1, 2);
        vm.stopPrank();
    }

    function testGetUserBetSlips() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        predictionMarket.placeBet{value: 1 ether}(marketId, 0);
        vm.stopPrank();

        (
            uint256[] memory marketIds,
            uint256[] memory eventIds,
            uint256[] memory totalBets,
            bool[] memory marketSettled,
            PredictionMarket.BetSlip[] memory betSlips
        ) = predictionMarket.getUserBetSlips(user1);

        assertEq(marketIds.length, 1);
        assertEq(marketIds[0], marketId);
        assertEq(eventIds[0], eventId);
        assertEq(totalBets[0], 1 ether);
        assertEq(marketSettled[0], false);
        assertEq(betSlips[0].better, user1);
        assertEq(betSlips[0].amount, 1 ether);
        assertEq(betSlips[0].outcome, 0);
    }

    function testGetTopBets() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        predictionMarket.placeBet{value: 1 ether}(marketId, 0);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.deal(user2, 2 ether);
        predictionMarket.placeBet{value: 2 ether}(marketId, 0);
        vm.stopPrank();

        PredictionMarket.BetSlip[] memory topBets = predictionMarket.getTopBets(marketId);

        assertEq(topBets.length, 2);
        assertEq(topBets[0].better, user2);
        assertEq(topBets[0].amount, 2 ether);
        assertEq(topBets[1].better, user1);
        assertEq(topBets[1].amount, 1 ether);
    }

    function testGetUserRankings() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        predictionMarket.placeBet{value: 1 ether}(marketId, 0);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.deal(user2, 1 ether);
        predictionMarket.placeBet{value: 1 ether}(marketId, 1);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(owner);
        eventOracle.settleEvent(eventId, 0);
        predictionMarket.settleMarket(marketId);
        vm.stopPrank();

        (address[] memory users, uint256[] memory totalBets, uint256[] memory prizes) =
            predictionMarket.getUserRankings();

        assertEq(users.length, 2);
        assertEq(users[0], user1);
        assertEq(totalBets[0], 1 ether);
        assertEq(prizes[0], 1.994 ether); // 1 ether bet * (2 ether total - 0.006 ether fee) / 1 ether winning total

        assertEq(users[1], user2);
        assertEq(totalBets[1], 1 ether);
        assertEq(prizes[1], 0);
    }

    function testGetTopUsers() public {
        vm.startPrank(owner);
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        predictionMarket.placeBet{value: 1 ether}(marketId, 0);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.deal(user2, 1 ether);
        predictionMarket.placeBet{value: 1 ether}(marketId, 1);
        vm.stopPrank();

        vm.startPrank(owner);
        eventOracle.settleEvent(eventId, 0);
        predictionMarket.settleMarket(marketId);
        vm.stopPrank();

        (address[] memory users, uint256[] memory totalBets, uint256[] memory prizes) = predictionMarket.getTopUsers();

        assertEq(users.length, 2);
        assertEq(users[0], user1);
        assertEq(totalBets[0], 1 ether);
        assertEq(prizes[0], 1.994 ether); // 1 ether bet * (2 ether total - 0.006 ether fee) / 1 ether winning total

        assertEq(users[1], user2);
        assertEq(totalBets[1], 1 ether);
        assertEq(prizes[1], 0);
    }
}
