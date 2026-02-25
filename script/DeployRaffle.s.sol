// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscriptionId} from "./interaction.s.sol";

contract DeployRaffle is Script{

    function run() public {}

    function deployRaffleContract() public returns (Raffle,HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getConfig();

        if(activeNetworkConfig.vrfCoordinator == address(0)){
            CreateSubscriptionId createSubscriptionId = new CreateSubscriptionId();
            (activeNetworkConfig.subscriptionId,activeNetworkConfig.vrfCoordinator) = 
            createSubscriptionId.createSubscription(activeNetworkConfig.vrfCoordinator);
             
            
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle({
            entranceFee: activeNetworkConfig.entranceFee,
            interval: activeNetworkConfig.interval, 
            vrfCoordinator: activeNetworkConfig.vrfCoordinator,
            gasLane: activeNetworkConfig.gasLane,
            subscriptionId: activeNetworkConfig.subscriptionId,
            callbackGasLimit: activeNetworkConfig.callbackGasLimit
            });
        vm.stopBroadcast();

        return (raffle,helperConfig);
    }
}