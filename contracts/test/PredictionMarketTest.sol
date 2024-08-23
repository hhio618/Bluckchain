// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PredictionMarket.sol";
import "../src/EventOracle.sol";
import "../src/BLUCKToken.sol";

contract PredictionMarketTest is Test {
    PredictionMarket public predictionMarket;
    EventOracle public eventOracle;
    BLUCKToken public bluckToken;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 public marketId = 1;
    uint256 public eventId = 1;

    function setUp() public {
        vm.startPrank(owner);
        bluckToken = new BLUCKToken();
        eventOracle = new EventOracle();
        predictionMarket = new PredictionMarket(address(eventOracle), address(bluckToken), address(0));

        bluckToken.mint(owner, 1e24); // Mint 1 million BLUCK tokens for the owner
        bluckToken.mint(user1, 1e22); // Mint 10,000 BLUCK tokens for user1
        bluckToken.mint(user2, 1e22); // Mint 10,000 BLUCK tokens for user2

        bluckToken.approve(address(predictionMarket), ~uint256(0)); // Approve BLUCK
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";
        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        predictionMarket.createMarket(eventId);
        marketId = predictionMarket.marketCount();
        vm.stopPrank();
        vm.startPrank(user1);
        bluckToken.approve(address(predictionMarket), ~uint256(0)); // Approve BLUCK
        vm.stopPrank();

        vm.startPrank(user2);
        bluckToken.approve(address(predictionMarket), ~uint256(0)); // Approve BLUCK
        vm.stopPrank();
    }

    function testCreateMarket() public {
        (uint256 eventId,, bool settled,, string memory description,, string[] memory outcomeNames,,) =
            predictionMarket.getMarketDetails(marketId);
        assertEq(eventId, 1);
        assertEq(settled, false);
        assertEq(description, "Test Event");
        assertEq(outcomeNames.length, 2);
        assertEq(outcomeNames[0], "Outcome1");
        assertEq(outcomeNames[1], "Outcome2");
    }

    function testSwap() public {
        vm.startPrank(user1);

        predictionMarket.swap(marketId, 0, 1e18); // Swap 1 BLUCK for Outcome1

        uint256 outcomePrice = predictionMarket.getMarketOutcomePrice(marketId, 0);
        assertTrue(outcomePrice > 0);

        uint256[] memory chances = predictionMarket.getMarketOutcomeChances(marketId);
        assertTrue(chances[0] > 0);
        vm.stopPrank();
    }

    function testPlaceLimitOrder() public {
        vm.startPrank(user1);

        predictionMarket.placeLimitOrder(marketId, 0, 1e18, 50, true); // Place a buy limit order

        uint256 outcomePrice = predictionMarket.getMarketOutcomePrice(marketId, 0);
        assertTrue(outcomePrice > 0);
        vm.stopPrank();
    }

    function testSettleMarket() public {
        vm.startPrank(owner);
        eventOracle.settleEvent(eventId, 0); // Settle the event with Outcome1 as the winner
        predictionMarket.createMarket(eventId);
        vm.stopPrank();

        vm.startPrank(user1);

        predictionMarket.swap(2, 0, 1e18); // Swap 1 BLUCK for Outcome1
        vm.stopPrank();

        vm.startPrank(owner);
        predictionMarket.settleMarket(2); // Settle the market

        (,,, uint256 finalOutcome,,,,,) = predictionMarket.getMarketDetails(2);
        assertEq(finalOutcome, 0);
        vm.stopPrank();
    }

    function testClaimReward() public {
        vm.startPrank(owner);
        eventOracle.settleEvent(eventId, 0); // Settle the event with Outcome1 as the winner
        predictionMarket.createMarket(eventId); // Settle the market
        uint256 marketId = predictionMarket.marketCount();
        vm.stopPrank();

        vm.startPrank(user1);

        predictionMarket.swap(marketId, 0, 1e18); // Swap 1 BLUCK for Outcome1
        vm.stopPrank();

        vm.startPrank(owner);
        predictionMarket.settleMarket(marketId);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 userBalanceBefore = bluckToken.balanceOf(user1);
        predictionMarket.claimReward(marketId);
        uint256 userBalanceAfter = bluckToken.balanceOf(user1);

        assertTrue(userBalanceAfter > userBalanceBefore);
        vm.stopPrank();
    }

    function testCancelOrder() public {
        vm.startPrank(user1);

        uint256 userBalanceBefore = bluckToken.balanceOf(user1);
        predictionMarket.placeLimitOrder(marketId, 0, 1e18, 50, true); // Place a buy limit order

        predictionMarket.cancelOrder(marketId, 0, 0);

        uint256 userBalanceAfter = bluckToken.balanceOf(user1);
        assertEq(userBalanceAfter, userBalanceBefore); // Ensure the BLUCK tokens are returned
        vm.stopPrank();
    }
}
