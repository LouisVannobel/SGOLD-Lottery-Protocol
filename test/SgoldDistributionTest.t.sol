// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../src/Sgold.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import "forge-std/Test.sol";

contract Receiver {
    receive() external payable {}
}

contract SgoldDistributionTest is Test {
    Sgold sgold;
    address user = address(0x1);
    Receiver treasury;
    Receiver lottery;
    MockPriceFeed priceFeed;

    function setUp() public {
        treasury = new Receiver();
        lottery = new Receiver();
        priceFeed = new MockPriceFeed(1e18, 18, "XAU/USD", 1);
        sgold = new Sgold(address(priceFeed), payable(address(treasury)), payable(address(lottery)));
        vm.deal(user, 10 ether);
    }

    function testMintDistribution() public {
        uint256 deposit = 1 ether;
        uint256 treasuryStart = address(treasury).balance;
        uint256 lotteryStart = address(lottery).balance;

        (, int256 price,,,) = sgold.priceFeed().latestRoundData();
        emit log_named_int("Price feed value before mint", price);
        assertGt(price, 0);

        vm.recordLogs();
        vm.prank(user);
        sgold.mint{value: deposit}();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool transferFailed = false;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics.length > 0 && entries[i].topics[0] == keccak256("TransferFailed(string,uint256)")) {
                transferFailed = true;
                emit log("TransferFailed event detected");
            }
        }
        assertEq(transferFailed, false, "A transfer failed during mint");

        uint256 sgoldBalance = sgold.balanceOf(user);
        uint256 treasuryBalance = address(treasury).balance - treasuryStart;
        uint256 lotteryBalance = address(lottery).balance - lotteryStart;

        assertApproxEqAbs(treasuryBalance, deposit * 20 / 100, 1e14);
        assertApproxEqAbs(lotteryBalance, deposit * 10 / 100, 1e14);
        assertGt(sgoldBalance, 0);
    }
}
