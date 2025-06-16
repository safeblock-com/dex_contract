// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IMultiswapRouterFacet - Multiswap Router Facet interface
/// @dev Multiswap Router interface
interface IMultiswapRouterFacet {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when the output amount is less than the minimum expected amount.
    error MultiswapRouterFacet_ValueLowerThanExpected(uint256 expectedGreaterValue, uint256 expectedLowerBalance);

    /// @dev Thrown when a Uniswap V2 swap fails.
    error MultiswapRouterFacet_FailedV2Swap();

    /// @dev Thrown when the `pairs` array is empty.
    error MultiswapRouterFacet_InvalidPairsArray();

    /// @dev Thrown when the `Multiswap2Calldata` struct contains invalid data.
    error MultiswapRouterFacet_InvalidMultiswap2Calldata();

    /// @dev Thrown when a Uniswap V3 swap fails due to zero liquidity.
    error MultiswapRouterFacet_FailedV3Swap();

    /// @dev Thrown when the `msg.sender` in the fallback is not the cached Uniswap V3 pool.
    error MultiswapRouterFacet_SenderMustBePool();

    /// @dev Thrown when the input amount exceeds the maximum value for `int256`.
    error MultiswapRouterFacet_InvalidIntCast();

    /// @dev Thrown when the input amount is zero.
    error MultiswapRouterFacet_InvalidAmountIn();

    // =========================
    // main logic
    // =========================

    /// @notice Configuration for a single-path swap.
    /// @dev Specifies the input token, amount, output constraints, and pool path for a single swap sequence.
    struct MultiswapCalldata {
        /// @notice The exact input amount for the swap.
        /// @dev Represents the total amount of `tokenIn` to be swapped.
        uint256 amountIn;
        /// @notice The minimum acceptable output amount.
        /// @dev Ensures the swap yields at least this amount of the output token, or it reverts.
        uint256 minAmountOut;
        /// @notice The address of the input token.
        /// @dev Can be an ERC20 token or address(0) for native currency (wrapped to Wrapped Native).
        address tokenIn;
        /// @notice The array of pool identifiers for the swap path.
        /// @dev Each bytes32 encodes:
        ///      - Bits 0-159: Pool address (20 bytes).
        ///      - Bits 160-183: Fee for Uniswap V2 pairs (3 bytes, ignored for V3).
        ///      - Bit 255: Protocol version (1 for Uniswap V3, 0 for Uniswap V2).
        bytes32[] pairs;
    }

    /// @notice Configuration for a multi-path swap with split input amounts.
    /// @dev Specifies the input token, total amount, output tokens, minimum outputs,
    ///      and multiple pool paths with percentage allocations.
    struct Multiswap2Calldata {
        /// @notice The total input amount for all swap paths.
        /// @dev Represents the full amount of `tokenIn` to be distributed across paths.
        uint256 fullAmount; // used for maxAmountIn in reverseMultiswap (project fee must be included)
        /// @notice The address of the input token.
        /// @dev Can be an ERC20 token or address(0) for native currency (wrapped to Wrapped Native).
        address tokenIn;
        /// @notice The array of output token addresses.
        /// @dev Specifies the tokens expected from each swap path.
        address[] tokensOut; // tokensOut for everyPath
        /// @notice The minimum acceptable output amounts for each output token.
        /// @dev Ensures each output token yields at least the corresponding amount, or it reverts.
        uint256[] minAmountsOut; // strict amountsOut for every path
        /// @notice The array of percentage allocations for the input amount.
        /// @dev Each percentage (in 1e18 scale) determines the portion of `fullAmount` used for the corresponding path in `pairs`. Must sum to 1e18.
        uint256[] amountInPercentages; // total tokensOut
        /// @notice The array of pool paths for each swap.
        /// @dev Each element is an array of bytes32 pool identifiers, where each bytes32 encodes:
        ///      - Bits 0-159: Pool address (20 bytes).
        ///      - Bits 160-183: Fee for Uniswap V2 pairs (3 bytes, ignored for V3).
        ///      - Bit 255: Protocol version (1 for Uniswap V3, 0 for Uniswap V2).
        bytes32[][] pairs;
    }

    /// @notice Executes a multi-path swap across Uniswap V2 and V3 pools.
    /// @dev Transfers input tokens, performs swaps through specified pools, applies fees,
    ///      and records output amounts. Reverts with various errors for invalid inputs, failed checks or failed swaps.
    /// @param data The swap configuration, including input token, pairs, amounts, and minimum outputs.
    function multiswap2(Multiswap2Calldata calldata data) external;

    /// @notice Executes a reverse multi-path swap across Uniswap V2 and V3 pools.
    /// @dev Transfers input tokens, performs swaps through specified pools in reverse order, applies fees,
    ///      and records output and input amounts.
    ///      Reverts with various errors for invalid inputs, failed checks or failed swaps.
    /// @param data The swap configuration, including input token, pairs, amounts, and minimum outputs.
    function multiswap2Reverse(IMultiswapRouterFacet.Multiswap2Calldata calldata data) external;
}
