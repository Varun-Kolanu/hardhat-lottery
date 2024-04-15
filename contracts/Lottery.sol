// Lottery

// Enter the lottery (pay amount)
// Pick a random no.
// Select winner every X minutes
// Chainlink Oracle -> Randomness, Automated execution

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

error Lottery__NotEnoughEthSent();

contract Lottery {
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    event LotteryEnter(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) revert Lottery__NotEnoughEthSent();
        s_players.push(payable(msg.sender));

        //Events
        // Name events with function name reversed
        emit LotteryEnter(msg.sender);
    }

    function pickRandomNumber() public {}

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address payable) {
        return s_players[index];
    }
}
