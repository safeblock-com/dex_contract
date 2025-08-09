// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IErrors
/// @notice Centralized error definitions for EntryPoint and all related facets and libraries.
/// @dev This interface defines custom errors used throughout the protocol for gas-efficient reverts.
interface IErrors {
    // =========================
    // EntryPoint errors
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
    // Ownable errors
    // =========================

    /// @dev Thrown when the caller is not the current contract owner.
    /// @param sender The address attempting the restricted action.
    error Ownable_SenderIsNotOwner(address sender);

    /// @dev Thrown when the caller is not the pending new owner in a two-step ownership transfer.
    /// @param caller The address attempting to accept ownership.
    error Ownable_CallerIsNotTheNewOwner(address caller);

    /// @dev Thrown when trying to set the new owner to the zero address.
    error Ownable_NewOwnerCannotBeAddressZero();

    // =========================
    // AcrossFacet errors
    // =========================

    /// @dev Thrown when `handleV3AcrossMessage` is called by an address other than the SpokePool.
    /// @dev Ensures only the designated SpokePool can trigger the message handler.
    error AcrossFacet_NotSpokePool();

    // =========================
    // MultiswapRouterFacet errors
    // =========================

    /// @dev Thrown when a Uniswap V2 swap fails.
    error MultiswapRouterFacet_FailedV2Swap();

    /// @dev Thrown when the provided `Multiswap2Calldata` is invalid or malformed.
    error MultiswapRouterFacet_InvalidMultiswap2Calldata();

    /// @dev Thrown when a Uniswap V3 swap fails, typically due to insufficient liquidity.
    error MultiswapRouterFacet_FailedV3Swap();

    /// @dev Thrown when the sender in the fallback function is not the expected Uniswap V3 pool.
    error MultiswapRouterFacet_SenderMustBePool();

    // =========================
    // StargateFacet errors
    // =========================

    /// @dev Thrown when `lzCompose` is called by an address other than the configured LayerZero endpoint.
    error StargateFacet_NotLZEndpoint();

    /// @dev Thrown when attempting to use Stargate with an unsupported native asset.
    /// @dev Stargate supports only ERC20 tokens; native tokens are not allowed.
    error StargateFacet_UnsupportedAsset();

    // =========================
    // TransferHelper errors
    // =========================

    /// @dev Thrown when `safeTransferFrom` fails to execute.
    error TransferHelper_TransferFromError();

    /// @dev Thrown when `safeTransfer` fails to execute.
    error TransferHelper_TransferError();

    /// @dev Thrown when `safeApprove` fails to update allowance.
    error TransferHelper_ApproveError();

    /// @dev Thrown when `safeGetBalance` fails to read the token balance.
    error TransferHelper_GetBalanceError();

    /// @dev Thrown when attempting to transfer native tokens and the operation fails.
    error TransferHelper_TransferNativeError();

    // =========================
    // HelperV2 errors
    // =========================

    /// @dev Thrown when the input amount is less than the required minimum in Uniswap V2-style pools.
    error UniswapV2_InsufficientInputAmount();

    /// @dev Thrown when the output amount is less than the required minimum in Uniswap V2-style pools.
    error UniswapV2_InsufficientOutputAmount();

    /// @dev Thrown when there's not enough liquidity in a Uniswap V2-style pool to execute the swap.
    error UniswapV2_InsufficientLiquidity();

    // =========================
    // Utils errors
    // =========================

    /// @dev Thrown when a uint256 value cannot be safely cast to int256.
    error InvalidIntCast();

    /// @dev Thrown when an expected greater value is actually lower than the comparison value.
    /// @param expectedGreaterValue The value that was expected to be larger.
    /// @param expectedLowerBalance The value that was expected to be smaller.
    error ValueLowerThanExpected(uint256 expectedGreaterValue, uint256 expectedLowerBalance);

    /// @dev Thrown when two values that were expected to match do not.
    error ValuesNotEqual();

    /// @dev Thrown when duplicate tokens are detected in an array that must be unique.
    error DuplicateToken();
}
