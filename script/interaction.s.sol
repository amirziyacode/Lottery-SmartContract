// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscriptionId is Script{
    function createSubscriptionUseConfig()public  returns(uint256,address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getConfig();
        (uint256 usdID,) = createSubscription(activeNetworkConfig.vrfCoordinator);
        return (usdID,activeNetworkConfig.vrfCoordinator);
    
    }

    function createSubscription(address  vrfCoordinator) public returns(uint64,address) {
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        return (uint64(subId),vrfCoordinator);
    }
    function run() public {}
}