// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/EventOracle.sol";

contract EventOracleTest is Test {
    EventOracle internal eventOracle;

    function setUp() public {
        eventOracle = new EventOracle();
    }

    function testCreateEvent() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);
        assertEq(eventOracle.eventCount(), 1);

        (string memory description, uint256 endTime, bool settled, uint256 outcome, string[] memory outcomes) = eventOracle.getEventDetails(1);
        assertEq(description, "Test Event");
        assertEq(endTime, block.timestamp + 1 days);
        assertFalse(settled);
        assertEq(outcomes[0], "Outcome1");
        assertEq(outcomes[1], "Outcome2");
    }

    function testSettleEvent() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        eventOracle.settleEvent(1, 0);

        (, , bool settled, uint256 outcome, ) = eventOracle.getEventDetails(1);
        assertTrue(settled);
        assertEq(outcome, 0);
    }

    function testSettleEventInvalidOutcome() public {
        string[] memory outcomeNames = new string[](2);
        outcomeNames[0] = "Outcome1";
        outcomeNames[1] = "Outcome2";

        eventOracle.createEvent("Test Event", block.timestamp + 1 days, outcomeNames);

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        vm.expectRevert("Invalid outcome");
        eventOracle.settleEvent(1, 2);
    }
}
