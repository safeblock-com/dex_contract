// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "./external/Ownable2Step.sol";
import { TransferHelper } from "./facets/libraries/TransferHelper.sol";

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { IFeeContract } from "./interfaces/IFeeContract.sol";

/// @title FeeContract
contract FeeContract is Ownable2Step, UUPSUpgradeable, Initializable, IFeeContract {
    // =========================
    // storage
    // =========================

    uint256 private constant FEE_MAX = 1_000_000;

    uint256 private constant PROTOCOL_PART_MASK = 0xffffffffffffffffffffffffffffffff;

    uint256 _protocolFee;
    mapping(address owner => mapping(address token => uint256 balance)) _profit;

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
    function profit(address owner, address token) external view returns (uint256 balance) {
        return _profit[owner][token];
    }

    /// @inheritdoc IFeeContract
    function fees() external view returns (uint256 protocolFee) {
        assembly ("memory-safe") {
            protocolFee := sload(_protocolFee.slot)
        }
    }

    // =========================
    // admin logic
    // =========================

    /// @inheritdoc IFeeContract
    function setRouter(address newRouter) external onlyOwner {
        _router = newRouter;
    }

    /// @inheritdoc IFeeContract
    function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
        if (newProtocolFee > FEE_MAX) {
            revert IFeeContract.FeeContract_InvalidFeeValue();
        }
        _protocolFee = newProtocolFee;
    }

    // =========================
    // fees logic
    // =========================

    /// @inheritdoc IFeeContract
    function collectProtocolFees(address token, address recipient, uint256 amount) external onlyOwner {
        uint256 balanceOf = _profit[address(this)][token];
        if (balanceOf < amount) {
            amount = balanceOf;
        }

        if (amount > 0) {
            unchecked {
                _profit[address(this)][token] -= amount;
            }
            TransferHelper.safeTransfer({ token: token, to: recipient, value: amount });
        }
    }

    /// @inheritdoc IFeeContract
    function writeFees(address token, uint256 amount) external returns (uint256 fee) {
        if (msg.sender != _router) {
            revert IFeeContract.FeeContract_InvalidSender({ sender: msg.sender });
        }

        unchecked {
            fee = (amount * _protocolFee) / FEE_MAX;
            _profit[address(this)][token] += fee;
        }
    }

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
