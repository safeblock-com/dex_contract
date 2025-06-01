// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { TransientStorageFacetLibrary } from "../../libraries/TransientStorageFacetLibrary.sol";
import { FeeLibrary } from "../../libraries/FeeLibrary.sol";

import { ISymbiosis } from "./interfaces/ISymbiosis.sol";
import { ISymbiosisFacet } from "./interfaces/ISymbiosisFacet.sol";

/// @title SymbiosisFacet
/// @notice A facet for executing cross-chain token bridging via the Symbiosis protocol in a diamond-like proxy contract.
/// @dev Handles token transfers, fee payments, and interactions with the Symbiosis Portal contract for meta-synthesis transactions.
contract SymbiosisFacet is ISymbiosisFacet {
    using TransferHelper for address;

    // =========================
    // storage
    // =========================

    /// @dev The address of the Symbiosis Portal contract.
    ///      Immutable, set during construction. Used to call `metaSynthesize` for cross-chain bridging.
    ISymbiosis internal immutable _portal;

    // =========================
    // constructor
    // =========================

    /// @notice Initializes the SymbiosisFacet with the Symbiosis Portal contract address.
    /// @dev Sets the immutable `_portal` address.
    /// @param portal_ The address of the Symbiosis Portal contract.
    constructor(address portal_) {
        _portal = ISymbiosis(portal_);
    }

    // =========================
    // getters
    // =========================

    /// @inheritdoc ISymbiosisFacet
    function portal() external view returns (address) {
        return address(_portal);
    }

    // =========================
    // main function
    // =========================

    /// @inheritdoc ISymbiosisFacet
    function sendSymbiosis(ISymbiosisFacet.SymbiosisTransaction calldata symbiosisTransaction) external {
        address sender = TransientStorageFacetLibrary.getSenderAddress();

        address token = symbiosisTransaction.rtoken;
        uint256 amount = symbiosisTransaction.amount;

        uint256 _amount = TransientStorageFacetLibrary.getAmountForToken({ token: token });
        if (_amount == 0) {
            TransferHelper.safeTransferFrom({ token: token, from: sender, to: address(this), value: amount });
        } else {
            amount = _amount;
        }

        amount = FeeLibrary.payFee({ token: token, amount: amount });

        token.safeApprove({ spender: address(_portal), value: amount });

        _portal.metaSynthesize({
            _metaSynthesizeTransaction: ISymbiosis.MetaSynthesizeTransaction({
                stableBridgingFee: symbiosisTransaction.stableBridgingFee,
                amount: amount,
                rtoken: token,
                chain2address: symbiosisTransaction.chain2address,
                receiveSide: 0xb8f275fBf7A959F4BCE59999A2EF122A099e81A8, // Synthesis on BOBA BNB
                oppositeBridge: 0x5523985926Aa12BA58DC5Ad00DDca99678D7227E, // BridgeV2 on BOBA BNB
                syntCaller: sender,
                chainID: 56_288, // Boba BNB
                swapTokens: symbiosisTransaction.swapTokens,
                secondDexRouter: 0xcB28fbE3E9C0FEA62E0E63ff3f232CECfE555aD4, // MulticallRouter on BOBA BNB
                secondSwapCalldata: symbiosisTransaction.secondSwapCalldata,
                finalReceiveSide: symbiosisTransaction.finalReceiveSide,
                finalCalldata: symbiosisTransaction.finalCalldata,
                finalOffset: symbiosisTransaction.finalOffset,
                revertableAddress: symbiosisTransaction.chain2address,
                clientID: bytes32("SafeBlock")
            })
        });
    }
}
