// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateComposer - StargateComposer interface
interface IStargateComposer {
    /// @notice LayerZero metadata for crosschain call and send native currency
    struct lzTxObj {
        // extra gas, if calling smart contract
        uint256 dstGasForCall;
        // amount of dstChain native currency dropped in destination wallet
        uint256 dstNativeAmount;
        // destination wallet for dstChain native currency
        bytes dstNativeAddr;
    }

    /// @notice Function for send cross-chain transaction
    /// @param dstChainId: destination chainId
    /// @param srcPoolId: source poolId
    /// @param dstPoolId: destination poolId
    /// @param refundAddress: extra gas (if any) is returned to this address
    /// @param amountLD: quantity to swap in LD (local decimals)
    /// @param minAmountLD: the min qty you would accept in LD (local decimals)
    /// @param lzTxParams: LayerZero metadata
    /// @param to: the address to send the tokens to on the destination
    /// @param payload: bytes param, if you wish to send additional payload
    function swap(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLD,
        uint256 minAmountLD,
        lzTxObj memory lzTxParams,
        bytes calldata to,
        bytes calldata payload
    )
        external
        payable;

    function factory() external view returns (address);

    /// @notice Router.sol method to get the value for swap()
    /// @param dstChainId: destination chainId
    /// @param functionType: function type - 1 for swap
    /// @param toAddress: destination of tokens
    /// @param transferAndCallPayload: payload
    /// @param lzTxParams: LayerZero metadata
    /// @return quote fee for StargateComposer swap method
    function quoteLayerZeroFee(
        uint16 dstChainId,
        uint8 functionType,
        bytes calldata toAddress,
        bytes calldata transferAndCallPayload,
        lzTxObj memory lzTxParams
    )
        external
        view
        returns (uint256, uint256);
}
