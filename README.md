
# Sgold Lottery Protocol

## Overview
This protocol implements a stablecoin (Sgold) backed by Ether, with an integrated lottery system using Chainlink Price Feed and Chainlink VRF v2.5. All logic and tests are compliant with the provided CDC and Chainlink documentation.

## Features
- **Sgold ERC20 Token**: Users mint Sgold by depositing Ether. 70% of the deposit is converted to Sgold using the Chainlink XAU/USD price feed.
- **Fund Distribution**: On mint, 20% of the deposit goes to the treasury, 10% to the lottery jackpot contract.
- **Lottery**: When 10 users have entered, the admin can trigger a random draw using Chainlink VRF. The winner receives the entire jackpot in Ether.
- **Collateral Redemption**: Users can burn Sgold to redeem their initial Ether collateral (70%).
- **Full Test Coverage**: All contracts and edge cases are covered by Foundry tests, including mocks for Chainlink Price Feed and VRF.

## How to Use
### Build
```sh
forge build
```

### Test
```sh
forge test
```

### Coverage
```sh
forge coverage
```

## Contracts
- `Sgold.sol`: Stablecoin logic, mint/burn, fund distribution.
- `Lottery.sol`: Lottery logic, VRF integration, jackpot payout.
- `Jackpot.sol`: Receives 10% of deposits, pays winner.
- Mocks for Chainlink Price Feed and VRF included for local testing.

## Deployment
- Update addresses for Chainlink Price Feed and VRF Coordinator in production.
- Use provided scripts or Foundry commands for deployment.

## Quick Start
1. Install Foundry and dependencies.
2. Run `forge build` and `forge test` to verify contracts and tests.
3. Review and adapt deployment scripts as needed.

---
MIT License
