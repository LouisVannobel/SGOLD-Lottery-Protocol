// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract Sgold is ERC20 {
    AggregatorV3Interface public priceFeed;
    address payable public treasury;
    address payable public jackpotContract;

    mapping(address => uint256) public initialDeposit;

    constructor(address _priceFeed, address payable _treasury, address payable _jackpot) ERC20("Sgold", "SGOLD") {
        priceFeed = AggregatorV3Interface(_priceFeed);
        treasury = _treasury;
        jackpotContract = _jackpot;
    }

    function mint() external payable {
        require(msg.value > 0, "Deposit required");
        (, int256 price,,,) = priceFeed.latestRoundData();
        if (price <= 0) {
            revert(string(abi.encodePacked("Chainlink price feed invalid: ", Strings.toString(uint256(price)))));
        }

        uint256 deposit = msg.value;
        uint256 sgoldAmount = (deposit * 70) / 100 * uint256(price) / 1e18;
        _mint(msg.sender, sgoldAmount);

        // Enregistre le montant du collatéral à rendre (70%)
        initialDeposit[msg.sender] += (deposit * 70) / 100;

        uint256 treasuryAmount = (deposit * 20) / 100;
        uint256 jackpotAmount = (deposit * 10) / 100;

        (bool sentTreasury, ) = treasury.call{value: treasuryAmount}("");
        if (!sentTreasury) {
            emit TransferFailed("Treasury", treasuryAmount);
        }
        require(sentTreasury, "Treasury transfer failed");
        (bool sentJackpot, ) = jackpotContract.call{value: jackpotAmount}("");
        if (!sentJackpot) {
            emit TransferFailed("Jackpot", jackpotAmount);
        }
        require(sentJackpot, "Jackpot transfer failed");
    }

    /**
     * @notice Permet à l'utilisateur de brûler ses Sgold pour récupérer son collatéral en Ether
     * Rend exactement le montant d'ETH déposé lors du mint
     */
    function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Not enough Sgold");
        _burn(msg.sender, amount);

        uint256 etherToReturn = initialDeposit[msg.sender];
        require(address(this).balance >= etherToReturn, "Not enough Ether in contract");
        initialDeposit[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: etherToReturn}("");
        require(sent, "Ether transfer failed");
    }

    event TransferFailed(string to, uint256 amount);
}
