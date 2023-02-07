// raffle

// enter the lottery ( paying some amount)

// pick a random winner( verifiab;ly random)

// winner be selected every xminutes => this should be completely be automated

// we need chain link since we are going to get the randomness from outside the blockchain auto selection triggers using chainlink keepers

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughEth();

error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__upKeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/**
 * @title a sample Rafffle contract
 * @author Evans Atoko
 * @notice this contract is for creating an untamperable decentralized smart contract
 * @dev this implements Chainlink VRFV2 and chainlink keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /*Types */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* state variables */

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //lottery variables

    address private s_recentWinner;
    // bool private s_isOpen; // to true, false
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /*events*/

    event RaffleEnter(address indexedplayer);
    event RequestedRaffleWinner(uint256 indexed rrequestId);
    event winnerPicked(address indexed winner);

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
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    /* functions */

    function enterRaffle() public payable {
        // require ( msg.value > i_entranceFee, " Not enough eth")
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));

        //we want to emit an event when we update a dynamic array or mapping
        //named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev this is the function that the chainlink keeper nodecall
     * thtey look for the upkeepneeded to return  true
     * the following should be true in order to return true
     * 1.our time interval should have passed
     * 2the lottery should have at least 1 player and have some eth
     * 3our subscribtion is funded with link
     * 4the lottery should be in an open state
     */

    function checkUpkeep(
        bytes memory /*checkdata */
    )
        public
        view
        override
        returns (bool upKeepNeeded, bytes memory /*performData */)
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;

        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

        //block.timestamp
    }

    function performUpkeep(bytes memory /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__upKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory RandomWords
    ) internal override {
        uint256 indexOfWinner = RandomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit winnerPicked(recentWinner);
    }

    /* view / pure / functions */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256){
        return s_players.length;
    }
    function getLatestTimestamp() public view returns(uint256) {
        return s_lastTimeStamp;
    }

    function requestConfirmations() public pure returns(uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
