// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {VRFV2PlusClient} from "../../lib/foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

contract MockVRFCoordinatorV2Plus {
    uint256 public lastRequestId;
    address public lastCaller;
    VRFV2PlusClient.RandomWordsRequest public lastRequest;
    uint256 public nextRequestId = 1;

    event RandomWordsRequested(uint256 requestId, address caller);

    function requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest calldata req
    ) external returns (uint256) {
        lastRequestId = nextRequestId++;
        lastCaller = msg.sender;
        lastRequest = req;
        emit RandomWordsRequested(lastRequestId, msg.sender);
        return lastRequestId;
    }

    // Helper for tests: call this to simulate VRF fulfillment
    function fulfill(address consumer, uint256 requestId, uint256[] memory randomWords) external {
        (bool success, ) = consumer.call(
            abi.encodeWithSignature("rawFulfillRandomWords(uint256,uint256[])", requestId, randomWords)
        );
        require(success, "fulfill failed");
    }
}
