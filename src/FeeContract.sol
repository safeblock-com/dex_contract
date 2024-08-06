// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "./external/Ownable2Step.sol";
import { TransferHelper } from "./facets/libraries/TransferHelper.sol";

import { IFeeContract } from "./interfaces/IFeeContract.sol";

/// @title FeeContract
contract FeeContract is Ownable2Step, IFeeContract {
    // =========================
    // storage
    // =========================

    uint256 private constant FEE_MAX = 10_000;

    uint256 private constant PROTOCOL_PART_MASK = 0xffffffffffffffffffffffffffffffff;

    uint256 _protocolFee;
    /// @dev protocolPart of referralFee: _referralFee & PROTOCOL_PART_MASK
    /// referralPart of referralFee: _referralFee >> 128
    uint256 _referralFee;
    mapping(address owner => mapping(address token => uint256 balance)) _profit;

    address private _router;

    // =========================
    // constructor
    // =========================

    constructor(address newOwner) {
        _transferOwnership(newOwner);
    }

    // =========================
    // getters
    // =========================

    function profit(address owner, address token) external view returns (uint256 balance) {
        return _profit[owner][token];
    }

    function fees() external view returns (uint256 protocolFee, ReferralFee memory referralFee) {
        assembly ("memory-safe") {
            protocolFee := sload(_protocolFee.slot)

            let referralFee_ := sload(_referralFee.slot)
            mstore(referralFee, and(PROTOCOL_PART_MASK, referralFee_))
            mstore(add(referralFee, 32), shr(128, referralFee_))
        }
    }

    // =========================
    // admin logic
    // =========================

    function changeRouter(address newRouter) external onlyOwner {
        _router = newRouter;
    }

    function changeProtocolFee(uint256 newProtocolFee) external onlyOwner {
        if (newProtocolFee > FEE_MAX) {
            revert FeeContract_InvalidFeeValue();
        }
        _protocolFee = newProtocolFee;
    }

    function changeReferralFee(ReferralFee calldata newReferralFee) external onlyOwner {
        unchecked {
            uint256 protocolPart = newReferralFee.protocolPart;
            uint256 referralPart = newReferralFee.referralPart;

            if ((referralPart + protocolPart) > _protocolFee) {
                revert FeeContract_InvalidFeeValue();
            }

            assembly ("memory-safe") {
                sstore(_referralFee.slot, or(shl(128, referralPart), protocolPart))
            }
        }
    }

    function writeFees(address referralAddress, address token, uint256 amount) external returns (uint256) {
        if (msg.sender != _router) {
            revert FeeContract_InvalidSender(msg.sender);
        }

        if (referralAddress == address(0)) {
            unchecked {
                uint256 fee = (amount * _protocolFee) / FEE_MAX;
                _profit[address(this)][token] += fee;

                TransferHelper.safeTransferFrom({ token: token, from: msg.sender, to: address(this), value: fee });

                return amount - fee;
            }
        } else {
            uint256 protocolPart;
            uint256 referralPart;
            assembly ("memory-safe") {
                let referralFee_ := sload(_referralFee.slot)
                protocolPart := and(PROTOCOL_PART_MASK, referralFee_)
                referralPart := shr(128, referralFee_)
            }

            unchecked {
                uint256 referralFeePart = (amount * referralPart) / FEE_MAX;
                uint256 protocolFeePart = (amount * protocolPart) / FEE_MAX;
                _profit[referralAddress][token] += referralFeePart;
                _profit[address(this)][token] += protocolFeePart;

                TransferHelper.safeTransferFrom({
                    token: token,
                    from: msg.sender,
                    to: address(this),
                    value: protocolFeePart + referralFeePart
                });

                return amount - referralFeePart - protocolFeePart;
            }
        }
    }

    // =========================
    // fees logic
    // =========================

    function collectProtocolFees(address token, address recipient, uint256 amount) external onlyOwner {
        uint256 balanceOf = _profit[address(this)][token];
        if (balanceOf >= amount) {
            unchecked {
                _profit[address(this)][token] -= amount;
            }
            TransferHelper.safeTransfer({ token: token, to: recipient, value: amount });
        }
    }

    function collectReferralFees(address token, address recipient, uint256 amount) external {
        uint256 balanceOf = _profit[msg.sender][token];
        if (balanceOf >= amount) {
            unchecked {
                _profit[msg.sender][token] -= amount;
            }
            TransferHelper.safeTransfer({ token: token, to: recipient, value: amount });
        }
    }

    function collectProtocolFees(address token, address recipient) external onlyOwner {
        uint256 balanceOf = _profit[address(this)][token];
        if (balanceOf > 0) {
            unchecked {
                _profit[address(this)][token] = 0;
            }
            TransferHelper.safeTransfer({ token: token, to: recipient, value: balanceOf });
        }
    }

    function collectReferralFees(address token, address recipient) external {
        uint256 balanceOf = _profit[msg.sender][token];
        if (balanceOf > 0) {
            unchecked {
                _profit[msg.sender][token] = 0;
            }
            TransferHelper.safeTransfer({ token: token, to: recipient, value: balanceOf });
        }
    }
}
