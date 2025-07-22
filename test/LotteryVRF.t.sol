// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {MockVRFCoordinatorV2Plus} from "./mocks/MockVRFCoordinatorV2Plus.sol";
import {Jackpot} from "../src/Jackpot.sol";
import {Lottery} from "../src/Lottery.sol";

contract LotteryVRFTest is Test {
    MockVRFCoordinatorV2Plus vrfCoordinator;
    Lottery lottery;
    Jackpot jackpotContract;
    address admin = address(0xA);
    address[] participants;

    address payable lotteryOwner;
    function setUp() public {
        vrfCoordinator = new MockVRFCoordinatorV2Plus();
        // Dummy values for subscriptionId and keyHash
        uint64 subscriptionId = 1;
        bytes32 keyHash = bytes32(uint256(123));
        jackpotContract = new Jackpot();
        lotteryOwner = payable(address(0xBEEF));
        vm.deal(lotteryOwner, 10 ether);
        lottery = new Lottery(subscriptionId, address(vrfCoordinator), keyHash, lotteryOwner, payable(address(jackpotContract)));
        // Ajoute 10 participants fictifs
        for (uint256 i = 0; i < 10; i++) {
            participants.push(address(uint160(i + 1)));
        }
    }

    function testLoterieAvecVRFMock() public {
        // Démarre la loterie
        lottery.startLottery();
        // Tous les participants entrent dans la loterie
        for (uint256 i = 0; i < participants.length; i++) {
            vm.deal(participants[i], 1 ether);
            vm.prank(participants[i]);
            lottery.enter{value: 1 ether}();
        }
        // L'admin déclenche le tirage
        vm.prank(admin);
        lottery.stopAndPickWinner();
        // Récupère le dernier requestId du mock
        uint256 requestId = vrfCoordinator.lastRequestId();
        // Simule la réponse VRF
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 7; // Le gagnant sera l'index 7
        // Log avant fulfillment
        emit log_named_uint("Jackpot contract balance before", jackpotContract.getBalance());
        emit log_named_uint("Lottery contract balance before", address(lottery).balance);
        vrfCoordinator.fulfill(address(lottery), requestId, randomWords);
        // Log après fulfillment
        emit log_named_uint("Jackpot contract balance after", jackpotContract.getBalance());
        emit log_named_uint("Lottery contract balance after", address(lottery).balance);
        // Vérifie que le gagnant est bien le bon participant
        assertEq(lottery.recentWinner(), participants[7], "Le gagnant n'est pas correct");
        // Vérifie que le gagnant a bien reçu la cagnotte
        emit log_named_uint("Winner balance after", participants[7].balance);
    }
}
