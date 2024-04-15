// Lottery

// Enter the lottery (pay amount)
// Pick a random no.
// Select winner every X minutes
// Chainlink Oracle -> Randomness, Automated execution

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

error Lottery__NotEnoughEthSent();

contract Lottery is VRFConsumerBaseV2 {
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    event LotteryEnter(address indexed player);

    constructor(
        address vrfCoordinator,
        uint256 entranceFee
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) revert Lottery__NotEnoughEthSent();
        s_players.push(payable(msg.sender));

        //Events
        // Name events with function name reversed
        emit LotteryEnter(msg.sender);
    }

    function pickRandomNumber() external {
        // Request random number
        // 2 transaction process
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address payable) {
        return s_players[index];
    }
}
