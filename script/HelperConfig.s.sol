// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";



abstract contract CodeConstant {
    //** VRF Mock Value  */
    uint96 public constant BASE_FEE = 0.25 ether;
    uint96 public constant GAS_PRICE_LINK = 1e9; 

    // LINK Ether /
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCALHOST_CHAINID = 31337;
}

contract HelperConfig  is Script, CodeConstant {

    //* Error * */
    error HelperConfig_NoNetworkFound();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    mapping (uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[SEPOLIA_CHAINID] = getSepoliaNetworkConfig();
        networkConfig[LOCALHOST_CHAINID] = getAnvilNetworkConfig();
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if(networkConfig[chainId].vrfCoordinator != address(0)){ // 0x000000000
            return networkConfig[chainId];
        } else if(chainId == LOCALHOST_CHAINID){
            return networkConfig[LOCALHOST_CHAINID];
        } else if (chainId == SEPOLIA_CHAINID){
            return networkConfig[SEPOLIA_CHAINID];
        }else {
            revert HelperConfig_NoNetworkFound();
        }
    }


    function getAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if(networkConfig[LOCALHOST_CHAINID].vrfCoordinator != address(0)){
            return networkConfig[LOCALHOST_CHAINID];
        }
        vm.startBroadcast();
            VRFCoordinatorV2_5Mock vrfCoordinatorV25mock = new VRFCoordinatorV2_5Mock(
                BASE_FEE,
                GAS_PRICE_LINK,
                MOCK_WEI_PER_UINT_LINK
            );
        vm.stopBroadcast();
        

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(vrfCoordinatorV25mock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000    
        });
    }
    
    function getSepoliaNetworkConfig() public view returns (NetworkConfig memory) {
        if(networkConfig[SEPOLIA_CHAINID].vrfCoordinator != address(0)){
            return networkConfig[SEPOLIA_CHAINID];
        }
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
           callbackGasLimit: 500000
        });
    }    
}