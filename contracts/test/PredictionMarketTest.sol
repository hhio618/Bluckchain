// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PredictionMarket.sol";
import "../src/EventOracle.sol";
import "../src/BLUCKToken.sol";

contract PredictionMarketTest is Test {
    EventOracle public eventOracle;
    BLUCKToken public bluckToken;
    PredictionMarket public predictionMarket;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        eventOracle = new EventOracle();
        bluckToken = new BLUCKToken();
        predictionMarket = new PredictionMarket(address(eventOracle), address(bluckToken), address(0x0));

        string[] memory outcomes = new string[](2);
        outcomes[0] = "Outcome1";
        outcomes[1] = "Outcome2";
        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomes);
        bluckToken.mint(owner, 1000 ether);
        bluckToken.mint(user1, 1000 ether);
        bluckToken.mint(user2, 1000 ether);
        vm.stopPrank();

        // Ensure users approve the PredictionMarket contract to spend their BLUCK tokens
        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        bluckToken.approve(address(predictionMarket), type(uint256).max);
        vm.stopPrank();
    }

    function testCreateMarket() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        (
            uint256 eventId,
            uint256 totalBets,
            bool marketSettled,
            uint256 outcome,
            string memory description,
            uint256 endTime,
            bool settled,
            uint256 eventOutcome,
            string[] memory outcomeNames
        ) = predictionMarket.getMarketDetails(1);
        assertEq(eventId, 1);
        assertEq(totalBets, 0);
        assertEq(settled, false);
    }

    function testPlaceLimitOrder() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), 1 ether);
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1, true);
        vm.stopPrank();

        // Check order book
        (
            address[] memory users,
            uint256[] memory amounts,
            uint256[] memory prices,
            bool[] memory isBuys,
            bool[] memory isLimits
        ) = predictionMarket.getOrderBook(1, 0);
        assertEq(users.length, 1);
        assertEq(users[0], user1);
        assertEq(amounts[0], 1 ether);
        assertEq(prices[0], 1);
        assertEq(isBuys[0], true);
        assertEq(isLimits[0], true);
    }

    function testPlaceMarketOrder() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        // User1 places a limit sell order
        vm.startPrank(user1);
        uint256 initialBalanceUser1 = bluckToken.balanceOf(user1);

        // Ensure user1 has a BetSlip for the outcome they want to sell
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1 ether, false);
        uint256 balanceAfterOrder1 = bluckToken.balanceOf(user1);
        assertEq(initialBalanceUser1, balanceAfterOrder1); // No BLUCK transferred yet for limit order
        vm.stopPrank();

        // User2 places a market buy order
        vm.startPrank(user2);
        uint256 initialBalanceUser2 = bluckToken.balanceOf(user2);
        predictionMarket.placeMarketOrder(1, 0, 1 ether, true);
        uint256 balanceAfterOrder2 = bluckToken.balanceOf(user2);
        assertEq(initialBalanceUser2 - 1 ether, balanceAfterOrder2); // BLUCK transferred for market order
        vm.stopPrank();

        // Verify the sell order was matched and removed
        (
            address[] memory users,
            uint256[] memory amounts,
            uint256[] memory prices,
            bool[] memory isBuys,
            bool[] memory isLimits
        ) = predictionMarket.getOrderBook(1, 0);
        assertEq(users.length, 0);

        // Verify balances after the market order
        uint256 finalBalanceUser1 = bluckToken.balanceOf(user1);
        uint256 finalBalanceUser2 = bluckToken.balanceOf(user2);
        assertEq(finalBalanceUser1, initialBalanceUser1 + 1 ether); // User1 received BLUCK for selling
        assertEq(finalBalanceUser2, initialBalanceUser2 - 1 ether); // User2 paid BLUCK for buying

        // Check user volumes
        uint256 volumeUser1 = predictionMarket.getVolume(user1);
        uint256 volumeUser2 = predictionMarket.getVolume(user2);
        assertEq(volumeUser1, 1 ether);
        assertEq(volumeUser2, 1 ether);
    }

    function testCancelOrder() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), 1 ether);
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1, true);
        predictionMarket.cancelOrder(1, 0, 0);
        vm.stopPrank();

        // Check order book is empty
        (
            address[] memory users,
            uint256[] memory amounts,
            uint256[] memory prices,
            bool[] memory isBuys,
            bool[] memory isLimits
        ) = predictionMarket.getOrderBook(1, 0);
        assertEq(users.length, 0);
    }

    function testSettleMarket() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 initialBalanceUser1 = bluckToken.balanceOf(user1);
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1, true);
        uint256 balanceAfterOrder = bluckToken.balanceOf(user1);
        assertEq(initialBalanceUser1 - 1 ether, balanceAfterOrder);
        vm.stopPrank();

        vm.startPrank(owner);
        eventOracle.settleEvent(1, 0); // Settle event with outcome 0
        predictionMarket.settleMarket(1);
        vm.stopPrank();

        uint256 finalBalanceUser1 = bluckToken.balanceOf(user1);
        assertEq(finalBalanceUser1, initialBalanceUser1);
        (
            uint256 eventId,
            uint256 totalBets,
            bool marketSettled,
            uint256 outcome,
            string memory description,
            uint256 endTime,
            bool settled,
            uint256 eventOutcome,
            string[] memory outcomeNames
        ) = predictionMarket.getMarketDetails(1);
        assertEq(settled, true);
        // Check that the orders were canceled and refunded
        (
            address[] memory users,
            uint256[] memory amounts,
            uint256[] memory prices,
            bool[] memory isBuys,
            bool[] memory isLimits
        ) = predictionMarket.getOrderBook(1, 0);
        assertEq(users.length, 0);
    }

    function testGetUserVolume() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), 1 ether);
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1, true);
        vm.stopPrank();

        uint256 volume = predictionMarket.getVolume(user1);
        assertEq(volume, 1 ether);
    }

    function testGetTopUsersByVolume() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), 1 ether);
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1, true);
        vm.stopPrank();

        vm.startPrank(user2);
        bluckToken.approve(address(predictionMarket), 2 ether);
        predictionMarket.placeLimitOrder(1, 0, 2 ether, 1, true);
        vm.stopPrank();

        (address[] memory users, uint256[] memory volumes) = predictionMarket.getTopUsersByVolume();
        assertEq(users[0], user2);
        assertEq(volumes[0], 2 ether);
        assertEq(users[1], user1);
        assertEq(volumes[1], 1 ether);
    }

    function testGetTopUsersByProfit() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), 1 ether);
        predictionMarket.placeLimitOrder(1, 0, 1 ether, 1, true);
        vm.stopPrank();

        vm.startPrank(owner);
        eventOracle.settleEvent(1, 0); // Settle event with outcome 0
        predictionMarket.settleMarket(1);
        vm.stopPrank();

        (address[] memory users, int256[] memory profits) = predictionMarket.getTopUsersByProfit();
        assertEq(users[0], user1);
        assertEq(profits[0], int256(1 ether) - int256(0.003 ether)); // Considering 0.3% fee
    }

    function testGetMarkets() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        (
            uint256[] memory marketIds,
            string[] memory descriptions,
            string[][] memory outcomes,
            uint256[] memory totalBets,
            uint256[] memory totalUniqueUsers
        ) = predictionMarket.getMarkets(false);
        assertEq(marketIds.length, 1);
        assertEq(descriptions[0], "Test Event");
        assertEq(outcomes[0][0], "Outcome1");
        assertEq(outcomes[0][1], "Outcome2");
        assertEq(totalBets[0], 0);
        assertEq(totalUniqueUsers[0], 0);
    }

    function testGetMarketDetails() public {
        vm.startPrank(owner);
        predictionMarket.createMarket(1);
        vm.stopPrank();

        (
            uint256 eventId,
            uint256 totalBets,
            bool marketSettled,
            uint256 outcome,
            string memory description,
            uint256 endTime,
            bool eventSettled,
            uint256 eventOutcome,
            string[] memory outcomeNames
        ) = predictionMarket.getMarketDetails(1);

        assertEq(eventId, 1);
        assertEq(totalBets, 0);
        assertEq(marketSettled, false);
        assertEq(outcome, 0);
        assertEq(description, "Test Event");
        assertEq(eventSettled, false);
        assertEq(outcomeNames[0], "Outcome1");
        assertEq(outcomeNames[1], "Outcome2");
    }
}
