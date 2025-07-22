// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ConfirmedOwner {
    address private _owner;

    constructor(address newOwner) {
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }
}
