// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { IWrappedNative } from "./interfaces/IWrappedNative.sol";

import { ITransferFacet } from "./interfaces/ITransferFacet.sol";
import { ISignatureTransfer } from "./interfaces/ISignatureTransfer.sol";

import { TransientStorageFacetLibrary } from "../libraries/TransientStorageFacetLibrary.sol";

/// @title TransferFacet - Facet for token transfers
contract TransferFacet is ITransferFacet {
    // =========================
    // storage
    // =========================

    /// @dev address of the WrappedNative contract for current chain
    IWrappedNative private immutable _wrappedNative;

    /// @dev address of the Permit2 contract
    ISignatureTransfer private immutable _permit2;

    // =========================
    // constructor
    // =========================

    /// @notice Constructor
    constructor(address wrappedNative, address permit2) {
        _wrappedNative = IWrappedNative(wrappedNative);
        _permit2 = ISignatureTransfer(permit2);
    }

    // =========================
    // getters
    // =========================

    /// @inheritdoc ITransferFacet
    function getNonceForPermit2(address user) external view returns (uint256 nonce) {
        address permit2 = address(_permit2);

        assembly ("memory-safe") {
            for {
                let wordPosition

                // nonceBitmap(address,uint256) selector
                mstore(0, 0x4fe02b44)
                mstore(32, user)
                // re-write the third word in memory with zero
                mstore(64, wordPosition)
            } 1 {
                wordPosition := add(wordPosition, 1)
                mstore(64, wordPosition)
            } {
                // 28 - calldata start
                // 68 - calldata length
                // 96 - returndata start
                // 32 - returndata length
                pop(staticcall(gas(), permit2, 28, 68, 96, 32))

                let result := mload(96)

                switch result
                case 0 {
                    nonce := shl(8, wordPosition)
                    break
                }
                case 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff { continue }
                default {
                    if eq(and(result, 0xffffffffffffffffffffffffffffffff), 0xffffffffffffffffffffffffffffffff) {
                        result := shr(128, result)
                        nonce := add(nonce, 128)
                    }

                    if eq(and(result, 0xffffffffffffffff), 0xffffffffffffffff) {
                        result := shr(64, result)
                        nonce := add(nonce, 64)
                    }
                    if eq(and(result, 0xffffffff), 0xffffffff) {
                        result := shr(32, result)
                        nonce := add(nonce, 32)
                    }
                    if eq(and(result, 0xffff), 0xffff) {
                        result := shr(16, result)
                        nonce := add(nonce, 16)
                    }
                    if eq(and(result, 0xff), 0xff) {
                        result := shr(8, result)
                        nonce := add(nonce, 8)
                    }
                    if eq(and(result, 0x0f), 0x0f) {
                        result := shr(4, result)
                        nonce := add(nonce, 4)
                    }
                    if eq(and(result, 3), 3) {
                        result := shr(2, result)
                        nonce := add(nonce, 2)
                    }
                    if eq(and(result, 1), 1) {
                        result := shr(1, result)
                        nonce := add(nonce, 1)
                    }

                    nonce := add(nonce, shl(8, wordPosition))

                    break
                }
            }
        }
    }

    // =========================
    // functions
    // =========================

    /// @inheritdoc ITransferFacet
    function transferFromPermit2(
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    )
        external
    {
        uint256 balanceBefore = TransferHelper.safeGetBalance({ token: token, account: address(this) });

        if (amount > 0) {
            _permit2.permitTransferFrom({
                permit: ISignatureTransfer.PermitTransferFrom({
                    permitted: ISignatureTransfer.TokenPermissions({ token: token, amount: amount }),
                    nonce: nonce,
                    deadline: deadline
                }),
                transferDetails: ISignatureTransfer.SignatureTransferDetails({ to: address(this), requestedAmount: amount }),
                owner: TransientStorageFacetLibrary.getSenderAddress(),
                signature: signature
            });
        }

        unchecked {
            uint256 balanceAfter = TransferHelper.safeGetBalance({ token: token, account: address(this) });

            if (balanceAfter <= balanceBefore) {
                revert ITransferFacet.TransferFacet_TransferFromFailed();
            }

            balanceAfter = balanceAfter - balanceBefore;

            TransientStorageFacetLibrary.setAmountForToken({ token: token, amount: balanceAfter, record: true });
        }
    }

    /// @inheritdoc ITransferFacet
    function transferToken(address to, address[] calldata tokens) external {
        uint256 length = tokens.length;

        while (length > 0) {
            unchecked {
                --length;
            }
            address token = tokens[length];
            uint256 amount = TransientStorageFacetLibrary.getAmountForToken({ token: token });

            if (amount > 0) {
                TransferHelper.safeTransfer({ token: token, to: to, value: amount });
            }
        }
    }

    /// @inheritdoc ITransferFacet
    function unwrapNativeAndTransferTo(address to) external {
        uint256 amount = TransientStorageFacetLibrary.getAmountForToken({ token: address(_wrappedNative) });
        if (amount > 0) {
            _wrappedNative.withdraw({ wad: amount });

            TransferHelper.safeTransferNative({ to: to, value: amount });
        }
    }
}
