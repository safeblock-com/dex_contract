// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErrors {
    // =========================
    // EntryPoint errors
    // =========================

    /// @dev Thrown when a function selector is not registered in the EntryPoint.
    /// @param selector The 4-byte function selector that does not exist.
    error EntryPoint_FunctionDoesNotExist(bytes4 selector);

    /// @dev Thrown when attempting to add a module that is already registered.
    /// @param methodSignature The 4-byte function signature of the module.
    error EntryPoint_ModuleAlreadyAdded(bytes4 methodSignature);

    /// @dev Thrown when attempting to update or remove a module that is not registered.
    /// @param methodSignature The 4-byte function signature of the module.
    error EntryPoint_ModuleNotAdded(bytes4 methodSignature);

    error EntryPoint_CallerIsNotEntryPointAA();

    error EntryPoint_InvalidSignatureForAACall();

    // =========================
    // Ownable errors
    // =========================

    /// @notice Throws when the sender is not the owner.
    error Ownable_SenderIsNotOwner(address sender);

    /// @notice Throws when the new caller is not a pendingOwner.
    error Ownable_CallerIsNotTheNewOwner(address caller);

    /// @notice Throws when the new owner is not a valid owner account.
    error Ownable_NewOwnerCannotBeAddressZero();

    // =========================
    // AcrossFacet errors
    // =========================

    /// @dev Thrown when the caller of `handleV3AcrossMessage` is not the SpokePool.
    ///      Triggered if `msg.sender` does not match `_spokePool`.
    error AcrossFacet_NotSpokePool();

    // =========================
    // MultiswapRouterFacet errors
    // =========================

    /// @dev Thrown when a Uniswap V2 swap fails.
    error MultiswapRouterFacet_FailedV2Swap();

    /// @dev Thrown when the `pairs` array is empty.
    error MultiswapRouterFacet_InvalidPairsArray();

    /// @dev Thrown when the `Multiswap2Calldata` struct contains invalid data.
    error MultiswapRouterFacet_InvalidMultiswap2Calldata();

    /// @dev Thrown when a Uniswap V3 swap fails due to zero liquidity.
    error MultiswapRouterFacet_FailedV3Swap();

    /// @dev Thrown when the `msg.sender` in the fallback is not the cached Uniswap V3 pool.
    error MultiswapRouterFacet_SenderMustBePool();

    /// @dev Thrown when the input amount is zero.
    error MultiswapRouterFacet_InvalidAmountIn();

    // =========================
    // StargateFacet errors
    // =========================

    /// @dev Thrown when the contract’s native balance is insufficient for the required fee.
    ///      Triggered in `_validateNativeBalance` during `sendStargateV2`.
    error StargateFacet_InvalidNativeBalance();

    /// @dev Thrown when the caller of `lzCompose` is not the LayerZero endpoint.
    ///      Triggered in `lzCompose` if `msg.sender` does not match `_lzEndpointV2`.
    error StargateFacet_NotLZEndpoint();

    /// @dev Thrown when the Stargate pool’s token is the native currency (address(0)).
    ///      Triggered in `sendStargateV2` if the pool does not support ERC20 tokens.
    error StargateFacet_UnsupportedAsset();

    // =========================
    // TransferFacet errors
    // =========================

    /// @dev Thrown when a transfer via Permit2 fails to increase the contract's token balance.
    error TransferFacet_TransferFromFailed();

    // =========================
    // TransferHelper errors
    // =========================

    /// @notice Thrown when `safeTransferFrom` fails.
    error TransferHelper_TransferFromError();

    /// @notice Thrown when `safeTransfer` fails.
    error TransferHelper_TransferError();

    /// @notice Thrown when `safeApprove` fails.
    error TransferHelper_ApproveError();

    /// @notice Thrown when `safeGetBalance` fails.
    error TransferHelper_GetBalanceError();

    /// @notice Thrown when `safeTransferNative` fails.
    error TransferHelper_TransferNativeError();

    // =========================
    // TransientStorageFacetLibrary errors
    // =========================

    /// @dev Thrown when a token is not transferred from the contract after a call.
    error TransientStorageFacetLibrary_TokenNotTransferredFromContract();

    /// @dev Thrown when the sender address is zero during retrieval.
    error TransientStorageFacetLibrary_InvalidSenderAddress();

    // =========================
    // HelperV2 errors
    // =========================

    error UniswapV2_InsufficientInputAmount();
    error UniswapV2_InsufficientOutputAmount();
    error UniswapV2_InsufficientLiquidity();

    // =========================
    // Utils errors
    // =========================

    /// @dev Thrown when the amount exceeds the maximum value for `int256`.
    error InvalidIntCast();

    /// @dev Thrown when the expected greater value is less than the expected lower balance.
    error ValueLowerThanExpected(uint256 expectedGreaterValue, uint256 expectedLowerBalance);

    /// @dev Thrown when the values are not equal.
    error ValuesNotEqual();
}
