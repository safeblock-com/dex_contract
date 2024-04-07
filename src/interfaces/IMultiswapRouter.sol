// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiswapRouter {
    // =========================
    // errors
    // =========================

    error MultiswapRouter_InvalidFeeValue();
    error MultiswapRouter_SenderIsNotOwner();
    error MultiswapRouter_InvalidOutAmount();

    error MultiswapRouter_FailedV2Swap();

    error MultiswapRouter_InvalidPairsArray();
    error MultiswapRouter_InvalidPartswapCalldata();
    error MultiswapRouter_FailedV3Swap();
    error MultiswapRouter_SenderMustBeUniswapV3Pool();
    error MultiswapRouter_InvalidIntCast();
    error MultiswapRouter_NewOwnerIsZeroAddress();

    // =========================
    // constructor
    // =========================

    function initialize(uint256 protocolFee, ReferralFee calldata newReferralFee, address newOwner) external;

    // =========================
    // fees logic
    // =========================

    struct ReferralFee {
        uint256 protocolPart;
        uint256 referralPart;
    }

    /// @notice Returns the current proxy version
    function getVersion() external view returns (uint8);

    function fees() external view returns (uint256 protocolFee, ReferralFee memory referralFee);

    function changeProtocolFee(uint256 newProtocolFee) external;

    function changeReferralFee(ReferralFee memory newReferralFee) external;

    // =========================
    // main logic
    // =========================

    function collectProtocolFees(address token, address recipient, uint256 amount) external;

    function collectReferralFees(address token, address recipient, uint256 amount) external;

    function collectProtocolFees(address token, address recipient) external;

    function collectReferralFees(address token, address recipient) external;

    struct MultiswapCalldata {
        // initial exact value in
        uint256 amountIn;
        // minimal amountOut
        uint256 minAmountOut;
        // first token in swap
        address tokenIn;
        // array of bytes32 values (pairs) involved in the swap
        // from left to right:
        //     address of the pair - 20 bytes
        //     fee in pair - 3 bytes (for V2 pairs)
        //     the highest bit shows which version the pair belongs to
        bytes32[] pairs;
        // an optional address that slightly relaxes the protocol's fees in favor of that address
        // and the user who called the multiswap
        address referralAddress;
    }

    /// @notice Swaps through the data.pairs array
    function multiswap(MultiswapCalldata calldata data) external;

    struct PartswapCalldata {
        // exact value in for part swap
        uint256 fullAmount;
        // minimal amountOut
        uint256 minAmountOut;
        // token in
        address tokenIn;
        // token out
        address tokenOut;
        // array of amounts for each swap, corresponding to the address for the swap from the pairs array
        uint256[] amountsIn;
        // array of bytes32 values (pairs) involved in the swap
        // from left to right:
        //     address of the pair - 20 bytes
        //     fee in pair - 3 bytes (for V2 pairs)
        //     the highest bit shows which version the pair belongs to
        bytes32[] pairs;
        // an optional address that slightly relaxes the protocol's fees in favor of that address
        // and the user who called the partswap
        address referralAddress;
    }

    /// @notice Swaps through each pair separately
    /// @dev each pair in the pairs array must have tokenIn and have the same tokenOut,
    /// the result of swap is the sum after each swap
    function partswap(PartswapCalldata calldata data) external;
}
