// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PredictionMarket.sol";
import "../src/EventOracle.sol";

contract PredictionMarketTest is Test {
    EventOracle internal eventOracle;
    PredictionMarket internal predictionMarket;
    address internal owner;

    function setUp() public {
        owner = address(this);
        eventOracle = new EventOracle();
        predictionMarket = new PredictionMarket(address(eventOracle));
    }

    function testCreateEventAndMarket() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        assertEq(eventOracle.eventCount(), 1);

        predictionMarket.createMarket(1);
        assertEq(predictionMarket.marketCount(), 1);
    }

    function testPlaceBet() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);

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
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);

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

        // Settle the event in the EventOracle
        eventOracle.settleEvent(1, 0);

        // Settle the market in PredictionMarket
        predictionMarket.settleMarket(1);

        // Check balances
        uint256 fee = (2 ether * 30) / 10000; // 0.3% fee
        assertEq(predictionMarket.accumulatedFees(), fee); // check accumulated fees
        assertEq(address(1).balance, 1 ether + (2 ether * 9970) / 10000); // winning bet minus fee
    }

    function testWithdrawFees() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);

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

        // Settle the event in the EventOracle
        eventOracle.settleEvent(1, 0);

        // Settle the market in PredictionMarket
        predictionMarket.settleMarket(1);

        // Withdraw the fees
        uint256 initialBalance = owner.balance;
        predictionMarket.withdrawFees();
        uint256 fee = (2 ether * 30) / 10000; // 0.3% fee
        assertEq(owner.balance, initialBalance + fee); // check owner's balance after withdrawal
    }

    function testSettleMarketInvalidOutcome() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(1);

        vm.deal(address(1), 1 ether);

        vm.startPrank(address(1));
        predictionMarket.placeBet{value: 1 ether}(1, 0);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        // Try to settle the event in the EventOracle with an invalid outcome
        vm.expectRevert("Invalid outcome");
        eventOracle.settleEvent(1, 2);
    }
}
