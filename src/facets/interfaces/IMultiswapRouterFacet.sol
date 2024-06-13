// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IMultiswapRouterFacet - Multiswap Router Facet interface
/// @dev Multiswap Router interface
interface IMultiswapRouterFacet {
    // =========================
    // errors
    // =========================

    /// @notice Throws if `fee` is invalid
    error MultiswapRouterFacet_InvalidFeeValue();

    /// @notice Throws if `sender` is not the owner
    error MultiswapRouterFacet_SenderIsNotOwner();

    /// @notice Throws if amount out is less than minimum amount out
    error MultiswapRouterFacet_InvalidOutAmount();

    /// @notice Throws if swap through UniswapV2 fails
    error MultiswapRouterFacet_FailedV2Swap();

    /// @notice Throws if `pairs` array is empty
    error MultiswapRouterFacet_InvalidArray();

    /// @notice Throws if `partswapCalldata` is invalid
    error MultiswapRouterFacet_InvalidPartswapCalldata();

    /// @notice Throws if swap through UniswapV3 fails
    error MultiswapRouterFacet_FailedV3Swap();

    /// @notice Throws if `sender` is not a UniswapV3 pool
    error MultiswapRouterFacet_SenderMustBeUniswapV3Pool();

    /// @notice Throws if `amount` is larger than `int256.max`
    error MultiswapRouterFacet_InvalidIntCast();

    /// @notice Throws if `newOwner` is the zero address
    error MultiswapRouterFacet_NewOwnerIsZeroAddress();

    /// @notice Throws if `sender` is not the wrapped native token for receive function
    error MultiswapRouterFacet_InvalidNativeSender();

    // =========================
    // getters
    // =========================

    /// @notice Returns the address of the `wrappedNative`
    function wrappedNative() external view returns (address);

    /// @notice Returns the balance of the `owner` for the `token`
    function profit(address owner, address token) external view returns (uint256 balance);

    struct ReferralFee {
        uint256 protocolPart;
        uint256 referralPart;
    }

    /// @notice Returns the protocolFee and the referralFee
    function fees() external view returns (uint256 protocolFee, ReferralFee memory referralFee);

    // =========================
    // admin logic
    // =========================

    /// @notice Changes the protocol fee for the contract
    function changeProtocolFee(uint256 newProtocolFee) external;

    /// @notice Changes the referral fee for the contract
    function changeReferralFee(ReferralFee memory newReferralFee) external;

    // =========================
    // fees logic
    // =========================

    /// @notice Collects the protocol fees with specified `amount`
    /// @dev Can only be called by the owner
    function collectProtocolFees(address token, address recipient, uint256 amount) external;

    /// @notice Collects the referral fees for the user with specified `amount`
    function collectReferralFees(address token, address recipient, uint256 amount) external;

    /// @notice Collects all protocol fees
    /// @dev Can only be called by the owner
    function collectProtocolFees(address token, address recipient) external;

    /// @notice Collects all referral fees for the user
    function collectReferralFees(address token, address recipient) external;

    // =========================
    // main logic
    // =========================

    struct MultiswapCalldata {
        // initial exact value in
        uint256 amountIn;
        // minimal amountOut
        uint256 minAmountOut;
        // first token in swap
        address tokenIn;
        // unwrap native tokenOut
        bool unwrap;
        // array of bytes32 values (pairs) involved in the swap
        // from right to left:
        //     address of the pair - 20 bytes
        //     fee in pair - 3 bytes (for V2 pairs)
        //     the highest bit shows which version the pair belongs to
        bytes32[] pairs;
        // an optional address that slightly relaxes the protocol's fees in favor of that address
        // and the user who called the multiswap
        address referralAddress;
    }

    /// @notice Swaps through the data.pairs array
    function multiswap(MultiswapCalldata calldata data, address to) external payable  returns(uint256);

    struct PartswapCalldata {
        // exact value in for part swap
        uint256 fullAmount;
        // minimal amountOut
        uint256 minAmountOut;
        // token in
        address tokenIn;
        // token out
        address tokenOut;
        // unwrap native tokenOut
        bool unwrap;
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

    /// @notice Swaps tokenIn through each pair separately
    /// @dev each pair in the pairs array must have tokenIn and have the same tokenOut,
    /// the result of swap is the sum after each swap
    function partswap(PartswapCalldata calldata data, address to) external payable;
}
