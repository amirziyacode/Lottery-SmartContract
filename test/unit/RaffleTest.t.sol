// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";


contract RaffleTest is Test{
    HelperConfig public helperNetWorConfig;
    Raffle public raffle;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLATER_BALANCE = 10 ether;
    event RaffleEnteranceFee(address indexed player);



    function setUp()external{
        DeployRaffle deployer = new DeployRaffle();
        (raffle,helperNetWorConfig) = deployer.deployRaffleContract();
        HelperConfig.NetworkConfig memory config = helperNetWorConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        
        vm.deal(PLAYER, STARTING_PLATER_BALANCE);
    }

    function tesRaffleInitializesInOpenState() public view {
        // assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // arrange
        vm.prank(PLAYER);
        // act
        vm.expectRevert(Raffle.Raffle_SendMoreEther.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // act
        address playerRecorded = raffle.getPlayer(0);

        // assert
        assert(playerRecorded == PLAYER);
    }

    function testRaffleEmitsEventOnEntrance() public {
        // arrange
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnteranceFee(PLAYER);

        // act
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayerEnterTheRaffle() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.timestamp + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    
}