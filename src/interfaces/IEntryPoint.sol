// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEntryPoint
/// @notice Interface for the EntryPoint contract
/// @dev This interface defines the functions for the main entry point of the DEX protocol.
///      The EntryPoint contract implements a diamond-like proxy pattern for dynamic function execution,
///      supporting module management, token transfers, fee handling, and multicall functionality.
interface IEntryPoint {
    /// @notice Information about a registered module
    struct ModuleInfo {
        /// @notice The 4-byte function signature of the module
        bytes4 moduleSignature;
        /// @notice The address of the module contract
        address moduleAddress;
    }

    // =========================
    // errors
    // =========================

    /// @dev Thrown when the function selector is not found in any facet or module.
    /// @param selector The 4-byte function selector that was not matched.
    error EntryPoint_FunctionDoesNotExist(bytes4 selector);

    /// @dev Thrown when attempting to add a module that is already registered.
    /// @param methodSignature The 4-byte signature of the module that is already added.
    error EntryPoint_ModuleAlreadyAdded(bytes4 methodSignature);

    /// @dev Thrown when trying to update or remove a module that was never added.
    /// @param methodSignature The 4-byte signature of the missing module.
    error EntryPoint_ModuleNotAdded(bytes4 methodSignature);

    /// @dev Thrown when a function is called externally but is restricted to internal delegation.
    error EntryPoint_OnlySelfCall();

    // =========================
    // initializer
    // =========================

    /// @notice Initializes a EntryPoint contract.
    /// @dev Sets the initial owner of the contract
    /// @param newOwner The address of the new owner
    function initialize(address newOwner) external;

    /// @notice Executes multiple function calls in a single transaction.
    /// @dev Delegates calls to appropriate facets or modules based on function selectors.

    // =========================
    // multicall
    // =========================

    /// @notice Executes a batch of function calls. Only callable internally.
    /// @dev Processes multiple function calls in sequence by delegating to appropriate facets or modules.
    /// @param data Array of encoded function calls to execute.
    function multicall(bytes[] calldata data) external;

    /// @notice Structure containing token addresses and amounts for transfers during multicall.
    struct TokenTransfers {
        /// @notice Array of token addresses
        address[] tokens;
        /// @notice Array of token amounts
        uint256[] amounts;
    }

    /// @notice Executes a batch of calls with input tokens sent via transfer or wrapping.
    /// @dev Handles token transfers and executes multiple function calls
    /// @param tokenTransfers Token addresses and amounts sent by user.
    /// @param data Encoded function calls to execute.
    function multicall(TokenTransfers calldata tokenTransfers, bytes[] calldata data) external payable;

    /// @notice Structure containing token addresses and amounts for transfers with permit2 during multicall.
    struct TokenTransfersPermit2 {
        /// @notice Array of token addresses
        address[] tokens;
        /// @notice Array of token amounts
        uint256[] amounts;
        /// @notice Nonce for the Permit2 signature
        uint256 nonce;
        /// @notice Deadline for the Permit2 signature
        uint256 deadline;
        /// @notice Signature for the Permit2 transfer
        bytes signature;
        /// @notice Token address for fee payment
        address feeToken;
        /// @notice Amount for fee payment
        uint256 feeAmount;
    }

    /// @notice Executes a batch of calls via Permit2 + EIP-712 witness meta-transaction.
    /// @dev Processes Permit2 transfers with EIP-712 witness and executes multiple function calls.
    ///      This function allows for gasless transactions where a relayer can execute calls on behalf of a user.
    /// @param sender The EOA signing the transaction.
    /// @param tokenTransfersPermit2 Permit2 structure with tokens and signature.
    /// @param data Encoded function calls to execute.
    function metaMulticall(
        address sender,
        TokenTransfersPermit2 calldata tokenTransfersPermit2,
        bytes[] calldata data
    )
        external;

    /// @notice Executes a batch of calls via Permit2 (no EIP-712 witness).
    /// @dev Processes Permit2 transfers and executes multiple function calls
    /// @param tokenTransfersPermit2 Permit2 structure with tokens and signature.
    /// @param data Encoded function calls.
    function multicall(TokenTransfersPermit2 calldata tokenTransfersPermit2, bytes[] calldata data) external;

    // =========================
    // admin methods
    // =========================

    /// @notice Sets the fee contract address and fee amount.
    /// @dev Only callable by the owner. Updates the fee configuration in FeeLibrary.
    /// @param feeContractAddress The address of the fee contract.
    /// @param fee The fee amount to set.
    function setFeeContractAddressAndFee(address feeContractAddress, uint256 fee) external;

    /// @notice Retrieves the current fee contract address and fee amount.
    /// @dev Reads the fee configuration from FeeLibrary.
    /// @return feeContractAddress The address of the fee contract.
    /// @return fee The current fee amount.
    function getFeeContractAddressAndFee() external view returns (address feeContractAddress, uint256 fee);

    // =========================
    // diamond getters
    // =========================

    // These functions are expected to be called frequently by tools
    /// @notice Information about a facet and its function selectors
    struct Facet {
        /// @notice Address of the facet contract
        address facet;
        /// @notice Array of function selectors implemented by this facet
        bytes4[] functionSelectors;
    }

    /// @notice Retrieves all facets and their associated function selectors.
    /// @dev Reads facet and selector data from SSTORE2 storage.
    ///      This function is typically used by development tools and indexers to understand the contract's structure.
    /// @return _facets Array of Facet structs containing facet addresses and their selectors.
    function facets() external view returns (Facet[] memory _facets);

    /// @notice Retrieves the function selectors for a specific facet.
    /// @dev Returns an empty array if the facet is not found.
    ///      This function is useful for understanding which functions are implemented by a specific facet.
    /// @param facet The address of the facet contract.
    /// @return _facetFunctionSelectors Array of 4-byte function selectors.
    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory _facetFunctionSelectors);

    /// @notice Retrieves all facet addresses.
    /// @dev Reads facet addresses from SSTORE2 storage.
    ///      This function provides a list of all facet contracts currently registered with the EntryPoint.
    /// @return _facets Array of facet contract addresses.
    function facetAddresses() external view returns (address[] memory _facets);

    /// @notice Retrieves the facet address for a given function selector.
    /// @dev Returns zero if the selector is not found.
    ///      This function is used to determine which facet implements a specific function.
    /// @param functionSelector The 4-byte function selector.
    /// @return _facet The address of the facet contract.
    function facetAddress(bytes4 functionSelector) external view returns (address _facet);
}
