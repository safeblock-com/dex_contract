// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Utils } from "../../libraries/Utils.sol";
import { TransferHelper } from "../../libraries/TransferHelper.sol";
import { TransientStorageLibrary } from "../../libraries/TransientStorageLibrary.sol";

import { LayerZeroLib } from "../../libraries/LayerZeroLib.sol";

import { ICircleBridge } from "./interfaces/ICircleBridge.sol";
import { ILayerZeroEndpointV2 } from "../stargateFacet/interfaces/ILayerZeroEndpointV2.sol";

contract CelerCCTPFacet {
    ICircleBridge internal immutable _circleBridge;

    /// @dev The address of the LayerZero V2 endpoint contract.
    ///      Immutable, set during construction. Used for validating incoming compose messages in `lzCompose`.
    address private immutable _lzEndpointV2;

    address private immutable USDC;

    constructor(address circleBridge, address endpointV2, address USDC_) {
        _circleBridge = ICircleBridge(circleBridge);
        _lzEndpointV2 = endpointV2;
        USDC = USDC_;
    }

    function quoteTransfer(uint256 amount, uint64 dstChainId) external view returns (uint256 amountOut) {
        amountOut = _quoteTransfer(amount, dstChainId);
    }

    function _quoteTransfer(uint256 amount, uint64 dstChainId) internal view returns (uint256 amountOut) {
        (uint256 fee,,) = _circleBridge.totalFee({ amount: amount, dstChainId: dstChainId });

        if (fee < amount) {
            unchecked {
                amountOut = amount - fee;
            }
        }
    }

    function sendCircleBridge(
        uint64 dstChainId,
        address recipient,
        uint32 dstEid,
        address tokenOut,
        bytes calldata extraData
    )
        external
        returns (bytes32[] memory tokensAndAmounts)
    {
        tokensAndAmounts = Utils.decodeTokensAndAmountsArray();

        uint256 inputAmount = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: USDC });
        Utils.expectNotZero({ value: inputAmount });

        TransferHelper.safeApprove({ token: USDC, spender: address(_circleBridge), value: inputAmount });

        uint256 outputAmount = _quoteTransfer(inputAmount, dstChainId);
        Utils.expectNotZero({ value: outputAmount });

        recipient = LayerZeroLib.validateReceiver({
            receiver: recipient,
            sender: TransientStorageLibrary.getSenderAddress(),
            dstEid: dstEid,
            tokenIn: USDC,
            tokenOut: tokenOut,
            minAmountLD: outputAmount,
            extraData: extraData,
            endpoint: ILayerZeroEndpointV2(_lzEndpointV2)
        });

        _circleBridge.depositForBurn({
            amount: inputAmount,
            dstChainId: dstChainId,
            mintRecipient: Utils.addressToBytes32({ addr: recipient }),
            burnToken: USDC
        });
    }
}
