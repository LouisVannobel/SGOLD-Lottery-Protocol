// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {Lottery} from "../src/Lottery.sol";
import {MockVRFCoordinatorV2Plus} from "./mocks/MockVRFCoordinatorV2Plus.sol";
import {Jackpot} from "../src/Jackpot.sol";

contract LotteryTest is Test {
    Lottery lottery;
    MockVRFCoordinatorV2Plus vrfCoordinator;
    Jackpot jackpotContract;
    address[] participants;
    uint256 constant PARTICIPANT_THRESHOLD = 10;
    address admin = address(0xA);
    bytes32 keyHash = bytes32(uint256(123));
    uint64 subId = 1;
    address payable lotteryOwner;

    function setUp() public {
        vrfCoordinator = new MockVRFCoordinatorV2Plus();
        lotteryOwner = payable(address(0xBEEF));
        vm.deal(lotteryOwner, 10 ether); // Fournit une balance suffisante à l'owner
        jackpotContract = new Jackpot();
        vm.deal(lotteryOwner, 10 ether);
        lottery = new Lottery(subId, address(vrfCoordinator), keyHash, lotteryOwner, payable(address(jackpotContract)));
    }

    function test_LotteryTriggersAtThreshold() public {
        lottery.startLottery();
        uint256[] memory deposits = new uint256[](PARTICIPANT_THRESHOLD);
        deposits[0] = 1 ether;
        deposits[1] = 0.1 ether;
        deposits[2] = 0.5 ether;
        deposits[3] = 2 ether;
        deposits[4] = 0.01 ether;
        deposits[5] = 0.2 ether;
        deposits[6] = 0.3 ether;
        deposits[7] = 0.05 ether;
        deposits[8] = 0.04 ether;
        deposits[9] = 0.8 ether;
        for (uint256 i = 0; i < PARTICIPANT_THRESHOLD; i++) {
            address user = address(uint160(i + 1));
            participants.push(user);
            vm.deal(user, deposits[i]);
            vm.prank(user);
            lottery.enter{value: deposits[i]}();
        }
        // Seuil atteint, admin peut déclencher la loterie
        assertEq(lottery.getPlayers().length, PARTICIPANT_THRESHOLD);
        vm.prank(admin);
        lottery.stopAndPickWinner();
        // Récupérer le requestId du mock
        uint256 requestId = vrfCoordinator.lastRequestId();
        // Simuler la réponse VRF
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 7; // index arbitraire pour le test
        vrfCoordinator.fulfill(address(lottery), requestId, randomWords);
        // Calculer le total des dépôts et la cagnotte attendue
        uint256 totalDeposits = 1 ether + 0.1 ether + 0.5 ether + 2 ether + 0.01 ether + 0.2 ether + 0.3 ether + 0.05 ether + 0.04 ether + 0.8 ether;
        uint256 expectedJackpot = (totalDeposits * 10) / 100; // 10% des dépôts
        address winner = lottery.recentWinner();
        assertTrue(winner != address(0));
        // Vérifie que le gagnant a bien reçu la cagnotte via le contrat Jackpot
        assertEq(jackpotContract.lastWinner(), winner);
        assertEq(jackpotContract.lastAmount(), expectedJackpot);
    }
}
