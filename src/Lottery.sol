// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/console.sol";
import {Jackpot} from "./Jackpot.sol";

import {VRFConsumerBaseV2Plus} from "../lib/foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "../lib/foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

contract Lottery is VRFConsumerBaseV2Plus {
    address public lotteryOwner;
    address payable public jackpotContract;
    using VRFV2PlusClient for VRFV2PlusClient.RandomWordsRequest;

    // Plus de montant fixe, on accepte des dépôts variables
    bool public isActive;
    address[] public players;
    address public recentWinner;
    uint256 public totalDeposits;
    uint256 public jackpot;
    uint256 public treasury;

    // Chainlink VRF
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 200000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    mapping(uint256 => address[]) public requestToPlayers;

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address payable _lotteryOwner,
        address payable _jackpotContract
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        lotteryOwner = _lotteryOwner;
        jackpotContract = _jackpotContract;
    }

    function startLottery() external {
        require(!isActive, "Lottery already active");
        delete players;
        isActive = true;
    }

    function enter() external payable {
        require(isActive, "Lottery is not active");
        require(msg.value > 0, "Deposit must be > 0");
        players.push(msg.sender);
        totalDeposits += msg.value;
        uint256 jackpotShare = (msg.value * 10) / 100;
        uint256 treasuryShare = (msg.value * 20) / 100;
        jackpot += jackpotShare;
        treasury += treasuryShare;
        // Distribution des 20% au contract deployer
        (bool sentTreasury, ) = payable(lotteryOwner).call{value: treasuryShare}("");
        require(sentTreasury, "Treasury transfer failed");
        // Distribution des 10% à un contrat Jackpot séparé
        (bool sentJackpot, ) = jackpotContract.call{value: jackpotShare}("");
        require(sentJackpot, "Jackpot transfer failed");
    }

    function stopAndPickWinner() external {
        require(isActive, "Lottery not active");
        require(players.length >= 10, "Need at least 10 players");
        isActive = false;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
        requestToPlayers[requestId] = players;
    }

    event DebugJackpot(address winner, uint256 jackpot, uint256 contractBalance);

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address[] memory participants = requestToPlayers[requestId];
        uint256 winnerIndex = randomWords[0] % participants.length;
        address winner = participants[winnerIndex];
        recentWinner = winner;

        emit DebugJackpot(winner, jackpot, address(this).balance);
        // Ajout de console.log pour debug
        console.log("Winner:", winner);
        console.log("Jackpot:", jackpot);
        console.log("Contract balance:", address(this).balance);
        // Appel au contrat Jackpot pour payer le gagnant
        Jackpot(jackpotContract).payWinner(payable(winner), jackpot);
        jackpot = 0;
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getPot() external view returns (uint256) {
        return address(this).balance;
    }
}
