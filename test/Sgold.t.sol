// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {Sgold} from "../src/Sgold.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";

contract Receiver {
    receive() external payable {}
}

contract SgoldTest is Test {
    Sgold sgold;
    MockPriceFeed priceFeed;
    Receiver treasury;
    Receiver jackpot;
    address user = address(0x123);

    function setUp() public {
        treasury = new Receiver();
        jackpot = new Receiver();
        priceFeed = new MockPriceFeed(1e18, 18, "XAU/USD", 1);
        sgold = new Sgold(address(priceFeed), payable(address(treasury)), payable(address(jackpot)));
        vm.deal(user, 10 ether);
    }

    function testMintDistribution() public {
        priceFeed.setPrice(1e18);
        uint256 deposit = 1 ether;
        uint256 treasuryStart = address(treasury).balance;
        uint256 jackpotStart = address(jackpot).balance;
        vm.prank(user);
        sgold.mint{value: deposit}();
        (, int256 price,,,) = priceFeed.latestRoundData();
        uint256 expectedSgold = (deposit * 70) / 100 * uint256(price) / 1e18;
        assertEq(sgold.balanceOf(user), expectedSgold, "Sgold mint incorrect");
        uint256 expectedTreasury = (deposit * 20) / 100;
        assertEq(address(treasury).balance - treasuryStart, expectedTreasury, "Treasury incorrect");
        uint256 expectedJackpot = (deposit * 10) / 100;
        assertEq(address(jackpot).balance - jackpotStart, expectedJackpot, "Jackpot incorrect");
    }

    function testBurnRemboursement() public {
        priceFeed.setPrice(1e18);
        uint256 deposit = 1 ether;
        vm.deal(user, deposit);
        vm.prank(user);
        sgold.mint{value: deposit}();
        uint256 sgoldAmount = sgold.balanceOf(user);
        vm.prank(user);
        sgold.burn(sgoldAmount);
        assertEq(user.balance, (deposit * 70) / 100, "Remboursement incorrect");
        assertEq(sgold.balanceOf(user), 0, "Burn Sgold incorrect");
    }

    function testMintFailsIfPriceFeedInvalid() public {
        priceFeed.setPrice(0);
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert();
        sgold.mint{value: 1 ether}();
    }

    function testMintFailsIfNoDeposit() public {
        priceFeed.setPrice(1e18);
        vm.prank(user);
        vm.expectRevert();
        sgold.mint{value: 0}();
    }

    function testBurnFailsIfNotEnoughSgold() public {
        priceFeed.setPrice(1e18);
        vm.deal(user, 1 ether);
        vm.prank(user);
        sgold.mint{value: 1 ether}();
        vm.prank(user);
        vm.expectRevert();
        sgold.burn(2 ether);
    }
}
