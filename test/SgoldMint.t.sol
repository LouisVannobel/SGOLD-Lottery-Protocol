// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";


import {Sgold} from "../src/Sgold.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";

contract SgoldMintTest is Test {
    address user = address(0x123);
    address payable treasury = payable(address(0x456));
    address payable jackpot = payable(address(0x789));
    Sgold sgold;
    MockPriceFeed priceFeed;

    function setUp() public {
        priceFeed = new MockPriceFeed(1e18, 18, "XAU/USD", 1);
        sgold = new Sgold(address(priceFeed), treasury, jackpot);
    }

    function testMintDistribution() public {
        priceFeed.setPrice(1e18); // Prix simulé à 1 pour simplifier
        uint256 deposit = 1 ether;
        vm.deal(user, deposit);
        uint256 treasuryStart = treasury.balance;
        uint256 jackpotStart = jackpot.balance;
        vm.prank(user);
        sgold.mint{value: deposit}();

        // 70% en Sgold
        (, int256 price,,,) = priceFeed.latestRoundData();
        uint256 expectedSgold = (deposit * 70) / 100 * uint256(price) / 1e18;
        assertEq(sgold.balanceOf(user), expectedSgold, "Sgold minte incorrect");

        // 20% en trésorerie
        uint256 expectedTreasury = (deposit * 20) / 100;
        assertEq(treasury.balance - treasuryStart, expectedTreasury, "Tresorerie incorrecte");

        // 10% en cagnotte
        uint256 expectedJackpot = (deposit * 10) / 100;
        assertEq(jackpot.balance - jackpotStart, expectedJackpot, "Cagnotte incorrecte");
    }

    function testBurnRemboursement() public {
        priceFeed.setPrice(1e18); // Prix simulé à 1 pour simplifier
        uint256 deposit = 1 ether;
        vm.deal(user, deposit);
        vm.prank(user);
        sgold.mint{value: deposit}();

        uint256 sgoldAmount = sgold.balanceOf(user);
        vm.prank(user);
        sgold.burn(sgoldAmount);

        // L'utilisateur doit récupérer 70% de son dépôt initial
        assertEq(user.balance, (deposit * 70) / 100, "Remboursement incorrect");
        // Le solde Sgold doit être 0
        assertEq(sgold.balanceOf(user), 0, "Burn Sgold incorrect");
    }
}

