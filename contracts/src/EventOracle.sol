// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EventOracle is Ownable {
    struct Event {
        string description;
        uint256 endTime;
        bool settled;
        uint256 outcome;
        string[] outcomeNames;
        mapping(uint256 => uint256) outcomeOptions;
    }

    mapping(uint256 => Event) public events;
    uint256 public eventCount;

    event EventCreated(uint256 indexed eventId, string description, uint256 endTime, string[] outcomeNames);
    event EventSettled(uint256 indexed eventId, uint256 outcome, string outcomeName);

    constructor() Ownable(msg.sender) {}

    function createEvent(string memory _description, uint256 _endTime, string[] memory _outcomeNames)
        public
        onlyOwner
    {
        require(_endTime > block.timestamp, "End time must be in the future");
        require(_outcomeNames.length > 1, "There must be at least two possible outcomes");

        eventCount++;
        Event storage newEvent = events[eventCount];
        newEvent.description = _description;
        newEvent.endTime = _endTime;
        newEvent.outcomeNames = _outcomeNames;

        emit EventCreated(eventCount, _description, _endTime, _outcomeNames);
    }

    function settleEvent(uint256 _eventId, uint256 _outcome) public onlyOwner {
        Event storage eventInstance = events[_eventId];
        // TODO: uncomment for production
        // require(eventInstance.endTime <= block.timestamp, "Event not ended yet");
        require(!eventInstance.settled, "Event already settled");
        require(_outcome < eventInstance.outcomeNames.length, "Invalid outcome");

        eventInstance.outcome = _outcome;
        eventInstance.settled = true;

        emit EventSettled(_eventId, _outcome, eventInstance.outcomeNames[_outcome]);
    }

    function getEventDetails(uint256 _eventId)
        public
        view
        returns (
            string memory description,
            uint256 endTime,
            bool settled,
            uint256 outcome,
            string[] memory outcomeNames
        )
    {
        Event storage eventInstance = events[_eventId];
        return (
            eventInstance.description,
            eventInstance.endTime,
            eventInstance.settled,
            eventInstance.outcome,
            eventInstance.outcomeNames
        );
    }

    function getOutcomeName(uint256 _eventId, uint256 _outcome) public view returns (string memory) {
        Event storage eventInstance = events[_eventId];
        return eventInstance.outcomeNames[_outcome];
    }
}
