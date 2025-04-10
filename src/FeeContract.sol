// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "./external/Ownable2Step.sol";
import { TransferHelper } from "./facets/libraries/TransferHelper.sol";

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { IFeeContract } from "./interfaces/IFeeContract.sol";

import { IEntryPoint } from "./interfaces/IEntryPoint.sol";

import { FEE_MAX } from "./libraries/Constants.sol";

/// @title FeeContract
contract FeeContract is Ownable2Step, UUPSUpgradeable, Initializable, IFeeContract {
    using TransferHelper for address;

    // =========================
    // storage
    // =========================

    uint256 _protocolFee_deprecated;
    mapping(address owner => mapping(address token => uint256 balance)) _profit_deprecated;

    address private _router;

    // =========================
    // constructor
    // =========================

    constructor() {
        _disableInitializers();
    }

    function initialize(address newOwner, address newRouter) external initializer {
        _transferOwnership(newOwner);

        _router = newRouter;
    }

    // =========================
    // getters
    // =========================

    /// @inheritdoc IFeeContract
    function router() external view returns (address) {
        return _router;
    }

    /// @inheritdoc IFeeContract
    function profit(address token) external view returns (uint256 balance) {
        return TransferHelper.safeGetBalance({ account: address(this), token: token });
    }

    // =========================
    // admin logic
    // =========================

    /// @inheritdoc IFeeContract
    function setRouter(address newRouter) external onlyOwner {
        _router = newRouter;
    }

    // =========================
    // fees logic
    // =========================

    /// @inheritdoc IFeeContract
    function collectProtocolFees(address token, address recipient, uint256 amount) external onlyOwner {
        uint256 balanceOf = TransferHelper.safeGetBalance({ account: address(this), token: token });
        if (balanceOf < amount) {
            amount = balanceOf;
        }

        if (amount > 0) {
            TransferHelper.safeTransfer({ token: token, to: recipient, value: amount });
        }
    }

    function writeFees(address, uint256 amount) external view returns (uint256 fee) {
        if (msg.sender != _router) {
            revert IFeeContract.FeeContract_InvalidSender({ sender: msg.sender });
        }

        (, uint256 protocolFee) = IEntryPoint(_router).getFeeContractAddressAndFee();
        if (protocolFee > 0) {
            unchecked {
                fee = (amount * protocolFee) / FEE_MAX;
            }
        }
    }

    /// @notice Function to receive Native currency.
    receive() external payable { }

    // =========================
    // internal methods
    // =========================

    /// @dev Function that should revert IEntryPoint.when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    ///
    /// Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
    ///
    /// ```solidity
    /// function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
