// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Utils } from "../../libraries/Utils.sol";
import { TransferHelper } from "../../libraries/TransferHelper.sol";

import { ICrossCurveRouter } from "./interfaces/ICrossCurveRouter.sol";

/// @title CrossCurveFacet
/// @notice A facet for interacting with the CrossCurve protocol in a diamond-like proxy contract.
/// @dev This contract provides functionality to start cross-chain operations via the CrossCurve router.
///      This facet is part of the diamond proxy pattern and provides functionality for cross-chain operations
///      using the CrossCurve protocol. It integrates with the EntryPoint contract to route calls appropriately.
contract CrossCurveFacet {
    ICrossCurveRouter internal immutable _crossCurveRouter;

    /// @notice Initializes the CrossCurveFacet with the CrossCurve router address.
    /// @dev Sets the immutable `_crossCurveRouter` address.
    /// @param crossCurveRouter The address of the CrossCurve router contract.
    constructor(address crossCurveRouter) {
        _crossCurveRouter = ICrossCurveRouter(crossCurveRouter);
    }

    /// @notice Starts a cross-chain operation via the CrossCurve protocol.
    /// @dev This function prepares tokens for the cross-chain operation, approves the router, and initiates the operation.
    /// @param operations The array of operation names to execute.
    /// @param params The array of parameters for each operation.
    /// @param receipt The invoice details for the cross-chain operation including:
    ///        - chainId: The destination chain ID
    ///        - token: The token to send
    ///        - amount: The amount to send
    ///        - receiver: The recipient address
    ///        - executionPrice: The execution price for the operation
    /// @return tokensAndAmounts The updated array of token addresses and amounts after the operation.
    function startCrossCurve(
        string[] calldata operations,
        bytes[] calldata params,
        ICrossCurveRouter.Invoice calldata receipt
    )
        external
        returns (bytes32[] memory tokensAndAmounts)
    {
        tokensAndAmounts = Utils.decodeTokensAndAmountsArray();

        address tokenIn;
        uint256 signedAmountIn;
        assembly ("memory-safe") {
            let offset := add(params.offset, calldataload(params.offset))
            tokenIn := calldataload(add(32, offset))
            signedAmountIn := calldataload(add(64, offset))
        }
        Utils.strictCompareAmounts({ greaterValue: signedAmountIn, lowerValue: 0 });

        {
            uint256 amountIn = Utils.getAmountFromArrayAndDelete({ tokensAndAmounts: tokensAndAmounts, token: tokenIn });
            Utils.strictCompareAmounts({ greaterValue: amountIn, lowerValue: 0 });
            uint256 diff = Utils.compareAmountsWithDifference({ greaterValue: amountIn, lowerValue: signedAmountIn });

            if (diff > 0) {
                Utils.addElementToArrayOrAddAmount({
                    tokensAndAmounts: tokensAndAmounts,
                    element: Utils.encodeTokenAndAmount({ token: tokenIn, amount: diff })
                });
            }
        }

        TransferHelper.safeApprove({ token: tokenIn, spender: address(_crossCurveRouter), value: signedAmountIn });

        _crossCurveRouter.start{ value: receipt.executionPrice }({
            operations: operations,
            params: params,
            receipt: receipt
        });
    }
}
