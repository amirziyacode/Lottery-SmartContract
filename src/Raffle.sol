// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


/**
 * @title Raffle
 * @author Amirziya
 * @notice This is a simple raffle contract that allows users to enter a raffle by paying an entrance fee. The contract owner can pick a winner from the list of entrants.
 * @dev implements chailink VRF to pick a random winner from the list of entrants.
 */

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/VRFCoordinatorV2Interface.sol";


contract Raffle is VRFConsumerBaseV2 {

    /**
     * Errors
     */
    error Raffle_SendMoreEther();
    error Raffle_TranferFaild();
    error Raffle_RaffleNotOpen();

    uint256 public immutable I_ENTRANCE_FEE;
    /** @dev Duration Time of Lattery */
    uint256 private immutable I_INTERVAL;
    VRFCoordinatorV2Interface private immutable I_VRFCOORDINATOR;
    bytes32 private immutable I_GASLANE;
    uint256 private immutable I_SUBSCRIPTIONID;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable I_CALLBACKGASLIMIT;
    uint32 private constant NUM_WORDS = 1;
    address payable[] public sPlayers;
    address private sRecentWinnner;
    uint256 private lastTimeStamp;
    RaffleState private sRaffleState;

    enum RaffleState{OPEN,CALCULATION}

    /**  
     * Events
    */
    event RaffleEnteranceFee(address indexed  player);
    event WinnerPicked(address indexed winnner);
    error Raffle_RaffleNotOpen();

    constructor(uint256 entranceFee,uint256 interval,address vrfCoordinator,bytes32 gasLane,uint256 subscriptionId,uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;    
        I_VRFCOORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator); 
        I_GASLANE = gasLane;
        I_SUBSCRIPTIONID = subscriptionId;
        I_CALLBACKGASLIMIT = callbackGasLimit;
        
        lastTimeStamp = block.timestamp;

        sRaffleState = RaffleState.OPEN;
        
     }


    function enterRaffle() external payable {  
        if(msg.value < I_ENTRANCE_FEE){
            revert Raffle_SendMoreEther();
        }

        if(sRaffleState != RaffleState.OPEN){
            revert Raffle_RaffleNotOpen();
        }

        sPlayers.push(payable(msg.sender));
        emit RaffleEnteranceFee(msg.sender);
     }

    function pickWinner() external view {  
        if(block.timestamp - lastTimeStamp < I_INTERVAL){
            revert();
        }
        sRaffleState = RaffleState.CALCULATION;
        VRFCoordinatorV2Interface memory request = I_VRFCOORDINATOR.requestRandomWords({
            keyHash: KEY_HASH,
            subId: I_SUBSCRIPTIONID,
            minimumRequestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: I_CALLBACKGASLIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFCoordinatorV2Interface._argsToBytes(VRFCoordinatorV2Interface.ExtraArgs({nativePayment: false}))
        });

        uint256 requestId = request.requestRandomWords();    

    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfOwner = randomWords[0] % sPlayers.length;
        address payable recentWinner = sPlayers[indexOfOwner];
        sRecentWinner = recentWinner;

        sRaffleState = RaffleState.OPEN;
        sPlayers = new address payable[](0);
        lastTimeStamp = block.timestamp;
        
        emit WinnerPicked(recentWinner);

        (bool success,) = recentWinner.call{value:address(this).balance}("");

        if(!success){
            revert Raffle_TranferFaild();
        }  


    }
    /**
     *  Getter and Setter functions
     */

    function getEntercFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
}