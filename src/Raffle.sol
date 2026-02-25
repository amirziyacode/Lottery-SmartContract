// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


/**
 * @title Raffle
 * @author Amirziya
 * @notice This is a simple raffle contract that allows users to enter a raffle by paying an entrance fee. The contract owner can pick a winner from the list of entrants.
 * @dev implements chailink VRF to pick a random winner from the list of entrants.
 */

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {

    /**
     * Errors
     */
    error Raffle_SendMoreEther();
    error Raffle_TranferFaild();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 currentBalance,uint256 numPlayers,uint256 raffleState);


    uint256 public immutable I_ENTRANCE_FEE;
    /** @dev Duration Time of Lattery */
    uint256 private immutable I_INTERVAL;
    VRFCoordinatorV2Interface private immutable I_VRFCOORDINATOR;
    bytes32 private immutable I_GASLANE;
    uint64 private immutable I_SUBSCRIPTIONID;
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
    

    constructor(uint256 entranceFee,uint256 interval,address vrfCoordinator,bytes32 gasLane,uint64 subscriptionId,uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
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

        /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicitly, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = RaffleState.OPEN == sRaffleState;
        bool timePassed = ((block.timestamp - lastTimeStamp) > I_INTERVAL);
        bool hasPlayers = sPlayers.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(address(this).balance, sPlayers.length, uint256(sRaffleState));
        }

        sRaffleState = RaffleState.CALCULATION;

        // Will revert if subscription is not set and funded.
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_GASLANE,
                subId: I_SUBSCRIPTIONID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACKGASLIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function pickWinner() external {  
        if(block.timestamp - lastTimeStamp < I_INTERVAL){
            revert();
        }
        sRaffleState = RaffleState.CALCULATION;
        I_VRFCOORDINATOR.requestRandomWords({
            subId: I_SUBSCRIPTIONID,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            minimumRequestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: I_CALLBACKGASLIMIT,
            numWords: NUM_WORDS
            // extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgs({nativePayment: false}))
        });
        

    }
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % sPlayers.length;
        address payable recentWinner = sPlayers[indexOfWinner];
        sRecentWinnner = recentWinner;
        sPlayers = new address payable[](0);
        sRaffleState = RaffleState.OPEN;
        lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle_TranferFaild();
        }
    }
    /**
     *  Getter and Setter functions
     */

    function getEntercFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
    function getRaffleState() external view returns (RaffleState) {
        return sRaffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return sPlayers[index];
    }
}