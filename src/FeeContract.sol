// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "./external/Ownable2Step.sol";

import { Initializable } from "./proxy/Initializable.sol";
import { UUPSUpgradeable } from "./proxy/UUPSUpgradeable.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { E6 } from "./libraries/Constants.sol";

import { IFeeContract } from "./interfaces/IFeeContract.sol";
import { IEntryPoint } from "./interfaces/IEntryPoint.sol";

/// @title FeeContract
/// @notice Contract responsible for handling fee collection and distribution in the DEX protocol.
/// @dev This contract manages protocol fees, collects them from the router, and allows the owner to withdraw them.
///      It uses the UUPS upgradeable pattern for future upgrades.
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

    /// @notice Disables initializers to prevent implementation contract misuse
    /// @dev This constructor ensures that the implementation contract cannot be initialized
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the FeeContract with an owner and router address
    /// @dev Sets the initial owner and router address for the contract
    /// @param newOwner The address that will become the owner of the contract
    /// @param newRouter The address of the router contract that will interact with this fee contract
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

    /// @notice Calculates the protocol fee for a given amount based on the current fee configuration.
    /// @dev Only callable by the router contract. Calculates fees as a percentage of the amount.
    /// @param amount The amount to calculate fees for.
    /// @return fee The calculated protocol fee.
    function writeFees(address, uint256 amount) external view returns (uint256 fee) {
        if (msg.sender != _router) {
            revert IFeeContract.FeeContract_InvalidSender({ sender: msg.sender });
        }

        (, uint256 protocolFee) = IEntryPoint(_router).getFeeContractAddressAndFee();
        if (protocolFee > 0) {
            unchecked {
                fee = (amount * protocolFee) / E6;
            }
        }
    }

    /// @notice Function to receive Native currency.
    /// @dev Allows the contract to receive native currency (e.g., ETH)
    receive() external payable { }

    // =========================
    // internal methods
    // =========================

    /// @notice Authorizes contract upgrades
    /// @dev Only the owner can authorize upgrades to prevent unauthorized changes.
    ///      This function is called by {upgradeTo} and {upgradeToAndCall} functions.
    /// @param newImplementation The address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
