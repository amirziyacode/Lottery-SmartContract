// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


/**
 * @title Raffle
 * @author 0xD4rk3n
 * @notice This is a simple raffle contract that allows users to enter a raffle by paying an entrance fee. The contract owner can pick a winner from the list of entrants.
 * @dev implements chailink VRF to pick a random winner from the list of entrants.
 */

contract Raffle {

    /**
     * Errors
     */
    error Raffle_SendMoreEther();

    uint256 public immutable I_ENTRANCE_FEE;

    constructor(uint256 entranceFee) {
        I_ENTRANCE_FEE = entranceFee;
    }

    function enterRaffle() public payable {  
        if(msg.value < I_ENTRANCE_FEE){
            revert Raffle_SendMoreEther();
        }
     }

    function pickWinner() public {   }

    /**
     * Getter and Setter functions
     */

    function getEntercFee() public view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
}