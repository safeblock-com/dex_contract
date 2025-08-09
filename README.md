# Safeblock DEX Smart Contract

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.0-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Framework-Foundry-orange)](https://getfoundry.shi/)

### The smart contract enables exchanges within a single network through various DEXs or cross-network swaps from any token to any token.

## Table of Contents

- [Safeblock DEX Smart Contract](#safeblock-dex-smart-contract)
    - [The smart contract enables exchanges within a single network through various DEXs or cross-network swaps from any token to any token.](#the-smart-contract-enables-exchanges-within-a-single-network-through-various-dexs-or-cross-network-swaps-from-any-token-to-any-token)
  - [Table of Contents](#table-of-contents)
  - [Architecture](#architecture)
    - [EntryPoint (Diamond Proxy)](#entrypoint-diamond-proxy)
      - [Key Functionalities](#key-functionalities)
      - [Storage and Utilities](#storage-and-utilities)
      - [Functions](#functions)
    - [Facets](#facets)
  - [Features](#features)
  - [Technologies](#technologies)
  - [Project Structure](#project-structure)
  - [Installation](#installation)
  - [Environment Setup](#environment-setup)
  - [Deployment](#deployment)
    - [Deploy to a network:](#deploy-to-a-network)
    - [Deploy to a local testnet:](#deploy-to-a-local-testnet)
  - [Upgrade Process](#upgrade-process)
  - [Testing](#testing)
  - [License](#license)

## Architecture

The Safeblock DEX Smart Contract is built using the Diamond Proxy pattern (EIP-2535), which allows for modular and upgradeable smart contracts. The architecture consists of:

### EntryPoint (Diamond Proxy)
The `EntryPoint` contract serves as a proxy to facilitate dynamic function execution. It achieves this by mapping function selectors to designated facet contracts (external modules). This design enables modular functionality, where each function can be delegated to a specific facet, making the system flexible and upgradable.

#### Key Functionalities

1. **Storage of Selectors and Facets**:
   - The contract uses the `SSTORE2` library to store a combined array of function selectors and facet addresses. This array is stored in a single, efficient storage slot to reduce gas costs.
   - The selectors and addresses are organized so that each selector is mapped to a unique facet address.

2. **Function Delegation**:
   - `EntryPoint` uses a fallback function to delegate incoming function calls to the appropriate facet based on the function selector.
   - The `_getAddress` function employs binary search to identify the facet for a given selector, optimizing lookup time.
   - The contract also has multicall capabilities, which allow it to execute multiple functions in a single transaction, either with or without argument replacement.

#### Storage and Utilities

- **SSTORE2**: Efficient storage of large data (selectors and addresses).
- **Binary Search**: Used for fast, efficient retrieval of facet addresses from stored selectors.
- **Transient Storage**: Temporary storage for multicall sender address and callback address during execution.

#### Functions

- **multicall**: Executes a batch of function calls. It supports both straightforward execution and argument replacement modes.
- **_getAddress** and **_getAddresses**: Internal helper functions to retrieve facet addresses associated with specific selectors.

### Facets

The system is composed of multiple facets, each handling specific functionalities:

1. **MultiswapRouterFacet**: Handles token swaps across Uniswap V3 and Uniswap V2 protocols, supporting complex swap transactions like "multiswaps" and "partswaps".
2. **TransferFacet**: Handles token and native asset transfers with support for wrapping/unwrapping native tokens.
3. **StargateFacet**: Enables cross-chain messaging and token bridging using the Stargate protocol.
4. **LayerZeroFacet**: Facilitates cross-chain communication with the LayerZero protocol.
5. **SymbiosisFacet**: Handles cross-chain swaps using the Symbiosis protocol.
6. **AcrossFacet**: Manages cross-chain transfers using the Across protocol.
7. **CrossCurveFacet**: Enables cross-chain swaps using the Curve protocol.

## Features

- **Modular Architecture**: Each functionality is implemented in separate facets, allowing for independent upgrades.
- **Cross-Chain Compatibility**: Supports multiple cross-chain protocols (Stargate, LayerZero, Symbiosis, Across).
- **Gas Optimization**: Uses efficient storage patterns and binary search for function lookups.
- **Multi-Swap Support**: Complex swap operations across multiple DEXs in a single transaction.
- **Native Token Support**: Seamless handling of native and wrapped tokens.
- **Fee Management**: Configurable fee system with dedicated fee contract.
- **Permit2 Integration**: Supports gasless approvals using Uniswap's Permit2.
- **Multicall Capability**: Execute multiple function calls in a single transaction.

## Technologies

- [Solidity ^0.8.0](https://soliditylang.org/)
- [Foundry](https://getfoundry.sh/)
- [Forge-Std](https://github.com/foundry-rs/forge-std)
- [SSTORE2](https://github.com/sam-github/SSTORE2)
- [Diamond Proxy Pattern (EIP-2535)](https://eips.ethereum.org/EIPS/eip-2535)

## Project Structure

```
├── script/                    # Deployment and upgrade scripts
├── src/                       # Smart contract source files
│   ├── EntryPoint.sol         # Diamond proxy contract
│   ├── FeeContract.sol        # Fee management contract
│   ├── facets/                # Individual facet implementations
│   ├── interfaces/            # Contract interfaces
│   ├── libraries/             # Utility libraries
│   ├── proxy/                 # Proxy-related contracts
│   └── external/             # External contract dependencies
├── test/                      # Test files
└── lib/                       # External libraries
```

## Installation

1. Install [Foundry](https://getfoundry.sh/):
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/your-org/safeblock-dex.git
   cd safeblock-dex
   ```

3. Install dependencies:
   ```bash
   forge install
   ```

## Environment Setup

Copy the example environment file and configure your variables:

```bash
cp .env.example .env
```

Edit `.env` with your private key and RPC URLs:

```bash
PRIVATE_KEY=your_private_key_here
ETH_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
# Add other network RPC URLs as needed
```

## Deployment

### Deploy to a network:

```bash
forge script script/DeployContract.s.sol --sig "run(uint256)" 0 --rpc-url {network} --broadcast --verify
```

Replace `{network}` with the target network (e.g., ethereum, polygon, arbitrum).

For production deployments, use version 1, 2, or 3:
```bash
forge script script/DeployContract.s.sol --sig "run(uint256)" 1 --rpc-url {network} --broadcast --verify
```

### Deploy to a local testnet:

```bash
# Start Anvil local testnet
anvil

# In another terminal, deploy
forge script script/DeployContract.s.sol --sig "run(uint256)" 0 --rpc-url http://localhost:8545 --broadcast
```

After deployment, update the contract addresses in the `DeployEngine.sol` file in the `getContracts` method for the specific network.

## Upgrade Process

To upgrade specific facets:

1. Update the `.env` file with your private key and RPC URL.

2. In the `DeployEngine.sol` file, locate the `getContracts` function for your target network and set the addresses of the facets you want to upgrade to `address(0)`.

3. Run the deployment script:
   ```bash
   forge script script/DeployContract.s.sol --sig "run(uint256)" 0 --rpc-url {network} --broadcast --verify
   ```

For production upgrades, use the appropriate version number:
   ```bash
   forge script script/DeployContract.s.sol --sig "run(uint256)" 1 --rpc-url {network} --broadcast --verify
   ```

## Testing

Run all tests:
```bash
forge test
```

Run tests with gas reports:
```bash
forge test --gas-report
```

Run specific test files:
```bash
forge test -mp "Multiswap"
```

Generate coverage report:
```bash
forge coverage
```

Generate coverage report with lcov format (for HTML report):
```bash
forge coverage --report lcov
```

Generate HTML coverage report (requires lcov to be installed):
```bash
forge coverage --report lcov && genhtml lcov.info -o coverage
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

```
MIT License

Copyright (c) 2025 SafeBlock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
