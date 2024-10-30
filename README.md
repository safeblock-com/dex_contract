# Safeblock DEX Smart Contract

### The smart contract enables exchanges within a single network through various DEXs or cross-network swaps from any token to any token.

## EntryPoint

### Overview

The `EntryPoint` contract serves as a proxy to facilitate dynamic function execution. It achieves this by mapping function selectors to designated facet contracts (external modules). This design enables modular functionality, where each function can be delegated to a specific facet, making the system flexible and upgradable.

### Key Functionalities

1. **Storage of Selectors and Facets**:
   - The contract uses the `SSTORE2` library to store a combined array of function selectors and facet addresses. This array is stored in a single, efficient storage slot to reduce gas costs.
   - The selectors and addresses are organized so that each selector is mapped to a unique facet address.

2. **Function Delegation**:
   - `EntryPoint` uses a fallback function to delegate incoming function calls to the appropriate facet based on the function selector.
   - The `_getAddress` function employs binary search to identify the facet for a given selector, optimizing lookup time.
   - The contract also has multicall capabilities, which allow it to execute multiple functions in a single transaction, either with or without argument replacement.


### Storage and Utilities

- **SSTORE2**: Efficient storage of large data (selectors and addresses).
- **Binary Search**: Used for fast, efficient retrieval of facet addresses from stored selectors.
- **Transient Storage**: Temporary storage for multicall sender address and callback address during execution.

### Functions

- **multicall**: Executes a batch of function calls. It supports both straightforward execution and argument replacement modes.
- **_getAddress** and **_getAddresses**: Internal helper functions to retrieve facet addresses associated with specific selectors.

### Usage

The `EntryPoint` contract enables modular upgrades by allowing the system's logic to be divided across multiple facets. Its proxy-like behavior makes it ideal for applications that require dynamic and flexible function execution.

## Facets

The `MultiswapRouterFacet` contract is a multi-purpose router for handling token swaps across both Uniswap V3 and Uniswap V2 protocols. Its main purpose is to allow users to perform complex swap transactions, such as "multiswaps" (a series of sequential swaps across multiple pairs) and "partswaps" (swaps that split the input amount across different pairs). It supports native tokens (like ETH) by wrapping and unwrapping them as needed. The contract also includes configurable fees, which are transferred to a designated fee contract upon each transaction. 

The `TransferFacet` contract is a facet that handles token and native asset transfers. It includes functions to transfer ERC-20 tokens, transfer native assets (e.g., ETH), and unwrap wrapped native tokens (like WETH) into native tokens. The contract uses `TransferHelper` for secure transfers and supports transferring unwrapped native tokens directly to specified recipients. It also stores the address of the `WrappedNative` contract for the specific blockchain on which it is deployed.

`LayerZeroFacet` enables cross-chain communication with the LayerZero protocol, handling:

1. **Peer Management**: Manages trusted addresses for specific chains.
2. **Gas Limits**: Sets gas limits per chain, with a default fallback.
3. **Cross-Chain Transfers**: Sends deposits with native token drops and calculates required fees.

`StargateFacet` is a facet for cross-chain messaging and token bridging with the LayerZero protocol, providing:

1. **Cross-Chain Token Transfer**: Manages token transfers and associated fees across chains.
2. **Fee Quotation**: Calculates fees for cross-chain transactions based on destination, amount, and gas limit requirements.
3. **Message Composition and Callbacks**: Handles cross-chain callbacks and reverts transactions with a fallback mechanism in case of failure, ensuring the return of assets or funds.
---

### Deploy:

Add the private key and RPC URL to the `.env` file.

```bash
forge script script/DeployContract.s.sol -vvvv --rpc-url {network} --broadcast --verify    
```

After deployment, update the contract addresses in the `DeployEngine.sol` file in the `getContracts` method for {network}.

### Upgrade:

Add the private key and RPC URL to the `.env` file. 

Ensure that the addresses marked `*Proxy` for the target network are correctly filled in the `DeployEngine.sol` file. Replace the facets that need updating with `address(0)`.

```bash
forge script script/DeployContract.s.sol -vvvv --rpc-url {network} --broadcast --verify    
```

