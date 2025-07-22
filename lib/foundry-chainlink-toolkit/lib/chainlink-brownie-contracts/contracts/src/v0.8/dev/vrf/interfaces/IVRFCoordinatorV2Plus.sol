// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVRFCoordinatorV2Plus {
    function requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest calldata req
    ) external returns (uint256);
}

import {VRFV2PlusClient} from "../libraries/VRFV2PlusClient.sol";
