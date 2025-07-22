// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IVRFCoordinatorV2Plus.sol";
import "./interfaces/IVRFMigratableConsumerV2Plus.sol";
import "../../shared/access/ConfirmedOwner.sol";

abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  function setCoordinator(address _vrfCoordinator) public override onlyOwnerOrCoordinator {
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}
