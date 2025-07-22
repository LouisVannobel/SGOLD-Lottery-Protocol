// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVRFMigratableConsumerV2Plus {
    function setCoordinator(address _vrfCoordinator) external;
}
