// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Jackpot {
    address public lastWinner;
    uint256 public lastAmount;

    event JackpotReceived(address indexed from, uint256 amount);
    event JackpotPaid(address indexed to, uint256 amount);

    receive() external payable {
        emit JackpotReceived(msg.sender, msg.value);
    }

    function payWinner(address payable winner, uint256 amount) external {
        require(address(this).balance >= amount, "Not enough jackpot funds");
        lastWinner = winner;
        lastAmount = amount;
        (bool sent, ) = winner.call{value: amount}("");
        require(sent, "Jackpot payout failed");
        emit JackpotPaid(winner, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
