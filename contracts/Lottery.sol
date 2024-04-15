// Lottery

// Enter the lottery (pay amount)
// Pick a random no.
// Select winner every X minutes
// Chainlink Oracle -> Randomness, Automated execution

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
error Lottery__NotEnoughEthSent();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // Types
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_lastTimestamp;
    uint256 private immutable i_interval;

    // Lottery Variables
    address payable private s_recentWinner;
    LotteryState private s_lotteryState;

    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimestamp = block.timestamp;
        i_interval = interval;
    }

    function enterLottery() public payable {
        if (s_lotteryState != LotteryState.OPEN) revert Lottery__NotOpen();
        if (msg.value < i_entranceFee) revert Lottery__NotEnoughEthSent();
        s_players.push(payable(msg.sender));

        //Events
        // Name events with function name reversed
        emit LotteryEnter(msg.sender);
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        // Request random number
        // 2 transaction process
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded)
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, // requestId
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert Lottery__TransferFailed();
        emit WinnerPicked(recentWinner);
    }

    /**
     * @notice Checks if maintenance/upkeep is needed for the contract.
     * @dev Implement this function to define the logic for checking upkeep conditions.
     * 1. Our time interval must have passed
     * 2. The lottery should have atleast one player
     * 3. Our subscription be funded with LINK
     * 4. The lottery should be in "open" state
     * @return upkeepNeeded A boolean indicating whether maintenance/upkeep is needed.
     * @return performData Additional data, if any, required for performing upkeep, encoded as bytes.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (s_lotteryState == LotteryState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address payable) {
        return s_players[index];
    }

    function getRecentWInner() public view returns (address payable) {
        return s_recentWinner;
    }
}
