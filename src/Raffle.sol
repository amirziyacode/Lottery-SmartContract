// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


/**
 * @title Raffle
 * @author Amirziya
 * @notice This is a simple raffle contract that allows users to enter a raffle by paying an entrance fee. The contract owner can pick a winner from the list of entrants.
 * @dev implements chailink VRF to pick a random winner from the list of entrants.
 */

contract Raffle {

    /**
     * Errors
     */
    error Raffle_SendMoreEther();

    uint256 public immutable I_ENTRANCE_FEE;
    address payable[] public sPlayers;

    /** @dev duration of the lottery in seconde */
    uint256 private immutable I_INTERVAL;

    uint256 private lastTimeStamp;

    /**  
     * Events
    */
    event RaffleEnteranceFee(address indexed  player);

    constructor(uint256 entranceFee,uint256 interval) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        lastTimeStamp = block.timestamp;    
    }

    function enterRaffle() external payable {  
        if(msg.value < I_ENTRANCE_FEE){
            revert Raffle_SendMoreEther();
        }
        sPlayers.push(payable(msg.sender));
        emit RaffleEnteranceFee(msg.sender);
     }

    function pickWinner() external view {  
        if(block.timestamp - lastTimeStamp < I_INTERVAL){
            revert();
        }
     }
    /**
     *  Getter and Setter functions
     */

    function getEntercFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
}