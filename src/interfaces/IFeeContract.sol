// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IFeeContract - FeeContract interface
interface IFeeContract {
    // =========================
    // errors
    // =========================

    error FeeContract_InvalidFeeValue();
    error FeeContract_InvalidSender(address sender);

    struct ReferralFee {
        uint256 protocolPart;
        uint256 referralPart;
    }

    // =========================
    // getters
    // =========================

    function profit(address owner, address token) external view returns (uint256 balance);
    function fees() external view returns (uint256 protocolFee, ReferralFee memory referralFee);

    // =========================
    // admin logic
    // =========================

    function changeRouter(address newRouter) external;
    function changeProtocolFee(uint256 newProtocolFee) external;
    function changeReferralFee(ReferralFee memory newReferralFee) external;
    function collectProtocolFees(address token, address recipient) external;
    function collectProtocolFees(address token, address recipient, uint256 amount) external;
    function writeFees(address referralAddress, address token, uint256 amount) external returns (uint256);

    // =========================
    // fees logic
    // =========================

    function collectReferralFees(address token, address recipient) external;

    function collectReferralFees(address token, address recipient, uint256 amount) external;
}
