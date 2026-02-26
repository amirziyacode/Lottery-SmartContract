// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;


import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import{VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";


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

    modifier raffleEntered {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.timestamp + 1);
        _;
    }

    function testDontAllowPlayerEnterTheRaffle() public raffleEntered{
        raffle.enterRaffle{value: entranceFee}();
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    

    function testCheakUpKeppRaturnsFalseiIfHasNoBalance() public raffleEntered{
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

     function testCheakUpKeppRaturnsFalseiIfRaffleNotOpen() public raffleEntered{
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    //* not subscribe to the raffle

     function testCheakUpKeppRaturnsFalseiFTimeHasPassedAndHasBalanceAndIsOpen() public raffleEntered{

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
     }

     function testCheakUpKeepRaturnsFalseIfRaffleIsntOpen() public raffleEntered{
       raffle.enterRaffle{value: entranceFee}();

        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
     }

     function testCheakUpKeepRaturnsFaleIfEnoghTimeHasPass() public raffleEntered{
    
        raffle.enterRaffle{value: entranceFee}();
    

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
     }

     function testCheakUpKeepRaturnsTrueWhenAllParameterisGood()  public raffleEntered{
        raffle.enterRaffle{value: entranceFee}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
     }

     function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntered{
        raffle.enterRaffle{value: entranceFee}();

        raffle.performUpkeep("");
     }

     function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256   numberOfPlayers = 0;
        Raffle.RaffleState currentRaffleState = raffle.getRaffleState();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                currentBalance,
                numberOfPlayers,
                uint256(currentRaffleState)
            )
        );
        raffle.performUpkeep("");
     }


    function testPerformUpkeepRaffleStateAndEmitsRequestId() public raffleEntered{
        raffle.enterRaffle{value:entranceFee}();

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    function testFullfillrandomWordsCanOnlyBeCalledAfterPeformUpkeep(uint256 randomRequestId) public raffleEntered{

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFullfillrandomWordsPicksAWinnerResetsTheRaffleAndSendsMoney() public raffleEntered{
        raffle.enterRaffle{value: entranceFee}();

        uint256 additionalEntrants = 3;
        uint256  startIndex = 1;
        address expectedWinner = address(1);

        for (uint256 i = startIndex; i < additionalEntrants + startIndex; i++) {
            address player = address(uint160(i));
            hoax(player,1 ether);
            raffle.enterRaffle{value: entranceFee}(); 
        }

        uint256 startTimeStmap = raffle.getLastTimeStamp();


        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalnce = recentWinner.balance;
        uint256 endTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalnce == prize);
        assert(startTimeStmap < endTimeStamp);  
    }
}