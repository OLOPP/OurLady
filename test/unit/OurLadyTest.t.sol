// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

// // import {DeployOurLady} from "../../script/DeployOurLady.s.sol";
// import {OurLady} from "../../src/OurLady.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {Vm} from "forge-std/Vm.sol";
// import {StdCheats} from "forge-std/StdCheats.sol";
// import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

// contract OurLadyTest is StdCheats, Test {
//     /* Errors */
//     event RequestedLotteryWinner(uint256 indexed requestId);
//     event LotteryEnter(address indexed player);
//     event WinnerSelected(address indexed player);

//     OurLady public ourLady;
//     HelperConfig public helperConfig;

//     uint64 subscriptionId;
//     bytes32 gasLane;
//     uint256 automationUpdateInterval;
//     // uint256 raffleEntranceFee;
//     uint32 callbackGasLimit;
//     address vrfCoordinatorV2;

//     address public PARTICIPANT = makeAddr("participant");
//     uint256 public constant STARTING_USER_BALANCE = 10 ether;

//     function setUp() external {
//         DeployRaffle deployer = new DeployRaffle();
//         (raffle, helperConfig) = deployer.run();
//         vm.deal(PARTICIPANT, STARTING_USER_BALANCE);

//         (
//             ,
//             gasLane,
//             automationUpdateInterval,
//             callbackGasLimit,
//             vrfCoordinatorV2, // link
//             // deployerKey
//             ,

//         ) = helperConfig.activeNetworkConfig();
//     }

//     function testLotteryInitializesInOpenState() public view {
//         assert(ourLady.getLotteryState() == OurLady.LotteryState.OPEN);
//     }

//     /////////////////////////
//     // enterRaffle         //
//     /////////////////////////

//     // function testRaffleRevertsWHenYouDontPayEnought() public {
//     //     // Arrange
//     //     vm.prank(PLAYER);
//     //     // Act / Assert
//     //     vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
//     //     raffle.enterRaffle();
//     // }

//     // function testRaffleRecordsPlayerWhenTheyEnter() public {
//     //     // Arrange
//     //     vm.prank(PLAYER);
//     //     // Act
//     //     raffle.enterRaffle{value: raffleEntranceFee}();
//     //     // Assert
//     //     address playerRecorded = raffle.getPlayer(0);
//     //     assert(playerRecorded == PLAYER);
//     // }

//     // function testEmitsEventOnEntrance() public {
//     //     // Arrange
//     //     vm.prank(PARTICIPANT);

//     //     // Act / Assert
//     //     vm.expectEmit(true, false, false, false, address(raffle));
//     //     emit LotteryEnter(PARTICIPANT);
//     //     ourLady.enterLottery{value: raffleEntranceFee}();
//     // }

//     function testDontAllowPlayersToEnterWhileLotteryIsCalculating() public {
//         // Arrange
//         vm.prank(PARTICIPANT);
//         // raffle.enterRaffle{value: raffleEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);
//         ourLady.performUpkeep("");
//     }

//     // Act / Assert
//     //     vm.expectRevert(OurLady.Lottery__LotteryNotOpen.selector);
//     //     vm.prank(PARTICIPANT);
//     //     ourLady.enterRaffle{value: raffleEntranceFee}();
//     // }

//     /////////////////////////
//     // checkUpkeep         //
//     /////////////////////////

//     function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
//         // Arrange
//         vm.prank(PLAYER);
//         // raffle.enterLottery{value: lotteryEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);
//         raffle.performUpkeep("");
//         Lottery.LoteryState lotteryState = lottery.getLotteryState();
//         // Act
//         (bool upkeepNeeded, ) = lottery.checkUpkeep("");
//         // Assert
//         assert(LotteryState == Lottery.LoteryState.CALCULATING);
//         assert(upkeepNeeded == false);
//     }

//     // Can you implement this?
//     function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {}

//     function testCheckUpkeepReturnsTrueWhenParametersGood() public {
//         // Arrange
//         vm.prank(Participant);
//         // raffle.enterRaffle{value: raffleEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act
//         (bool upkeepNeeded, ) = lottery.checkUpkeep("");

//         // Assert
//         assert(upkeepNeeded);
//     }

//     /////////////////////////
//     // performUpkeep       //
//     /////////////////////////

//     function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
//         // Arrange
//         vm.prank(PLAYER);
//         raffle.enterRaffle{value: raffleEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act / Assert
//         // It doesnt revert
//         raffle.performUpkeep("");
//     }

//     function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
//         // Arrange
//         uint256 currentBalance = 0;
//         uint256 numPlayers = 0;
//         Raffle.RaffleState rState = raffle.getRaffleState();
//         // Act / Assert
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Raffle.Raffle__UpkeepNotNeeded.selector,
//                 currentBalance,
//                 numPlayers,
//                 rState
//             )
//         );
//         raffle.performUpkeep("");
//     }

//     function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
//         // Arrange
//         vm.prank(PLAYER);
//         raffle.enterRaffle{value: raffleEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);

//         // Act
//         vm.recordLogs();
//         raffle.performUpkeep(""); // emits requestId
//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         bytes32 requestId = entries[1].topics[1];

//         // Assert
//         Raffle.RaffleState raffleState = raffle.getRaffleState();
//         // requestId = raffle.getLastRequestId();
//         assert(uint256(requestId) > 0);
//         assert(uint(raffleState) == 1); // 0 = open, 1 = calculating
//     }

//     /////////////////////////
//     // fulfillRandomWords //
//     ////////////////////////

//     modifier raffleEntered() {
//         vm.prank(PLAYER);
//         raffle.enterRaffle{value: raffleEntranceFee}();
//         vm.warp(block.timestamp + automationUpdateInterval + 1);
//         vm.roll(block.number + 1);
//         _;
//     }

//     modifier skipFork() {
//         if (block.chainid != 31337) {
//             return;
//         }
//         _;
//     }

//     function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
//         public
//         raffleEntered
//         skipFork
//     {
//         // Arrange
//         // Act / Assert
//         vm.expectRevert("nonexistent request");
//         // vm.mockCall could be used here...
//         VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
//             0,
//             address(raffle)
//         );

//         vm.expectRevert("nonexistent request");

//         VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
//             1,
//             address(raffle)
//         );
//     }

//     function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
//         public
//         raffleEntered
//         skipFork
//     {
//         address expectedWinner = address(1);

//         // Arrange
//         uint256 additionalEntrances = 3;
//         uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

//         for (
//             uint256 i = startingIndex;
//             i < startingIndex + additionalEntrances;
//             i++
//         ) {
//             address player = address(uint160(i));
//             hoax(player, 1 ether); // deal 1 eth to the player
//             raffle.enterRaffle{value: raffleEntranceFee}();
//         }

//         uint256 startingTimeStamp = raffle.getLastTimeStamp();
//         uint256 startingBalance = expectedWinner.balance;

//         // Act
//         vm.recordLogs();
//         raffle.performUpkeep(""); // emits requestId
//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

//         VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
//             uint256(requestId),
//             address(raffle)
//         );

//         // Assert
//         address recentWinner = raffle.getRecentWinner();
//         Raffle.RaffleState raffleState = raffle.getRaffleState();
//         uint256 winnerBalance = recentWinner.balance;
//         uint256 endingTimeStamp = raffle.getLastTimeStamp();
//         uint256 prize = raffleEntranceFee * (additionalEntrances + 1);

//         assert(recentWinner == expectedWinner);
//         assert(uint256(raffleState) == 0);
//         assert(winnerBalance == startingBalance + prize);
//         assert(endingTimeStamp > startingTimeStamp);
//     }
// }
