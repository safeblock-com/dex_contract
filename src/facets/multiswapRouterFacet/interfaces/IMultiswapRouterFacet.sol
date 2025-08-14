// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IMultiswapRouterFacet - Multiswap Router Facet interface
/// @dev Multiswap Router interface
interface IMultiswapRouterFacet {
    // =========================
    // errors
    // =========================

    /// @dev Thrown when a Uniswap V2 swap fails.
    error MultiswapRouterFacet_FailedV2Swap();

    /// @dev Thrown when a Uniswap V3 swap fails, typically due to insufficient liquidity.
    error MultiswapRouterFacet_FailedV3Swap();

    /// @dev Thrown when the sender in the fallback function is not the expected Uniswap V3 pool.
    error MultiswapRouterFacet_SenderMustBePool();

    // =========================
    // main logic
    // =========================

    /// @notice Configuration for a single-path swap.
    /// @dev Specifies the input token, amount, output constraints, and pool path for a single swap sequence.
    struct MultiswapCalldata_legacy {
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
        uint256 fullAmount;
        /// @notice The address of the input token.
        /// @dev Can be an ERC20 token or address(0) for native currency (wrapped to Wrapped Native).
        address tokenIn;
        /// @notice The array of output token addresses.
        /// @dev Specifies the tokens expected from each swap path.
        address[] tokensOut;
        /// @notice The minimum acceptable output amounts for each output token.
        /// @dev Ensures each output token yields at least the corresponding amount, or it reverts.
        uint256[] minAmountsOut;
        /// @notice The array of percentage allocations for the input amount.
        /// @dev Each percentage (in 1e18 scale) determines the portion of `fullAmount` used for the corresponding path in `pairs`. Must sum to 1e18.
        uint256[] amountInPercentages;
        /// @notice The array of pool paths for each swap.
        /// @dev Each element is an array of bytes32 pool identifiers, where each bytes32 encodes:
        ///      - Bits 0-159: Pool address (20 bytes).
        ///      - Bits 160-183: Fee for Uniswap V2 pairs (3 bytes, ignored for V3).
        ///      - Bit 255: Protocol version (1 for Uniswap V3, 0 for Uniswap V2).
        bytes32[][] pairs;
    }

    /// @notice Struct containing parameters for a multiswap operation with forward routing.
    /// @dev Used in `multiswap()` to perform a sequence of swaps across multiple pools (V2/V3),
    ///      starting from a list of input tokens and resulting in a set of expected output tokens.
    struct MultiswapCalldata {
        /// @notice An array of encoded input tokens and their source indices.
        /// @dev Each element is a bytes32 value where:
        ///      - Lower 160 bits represent the input token address.
        ///      - Higher 96 bits represent the index of the path this token belongs to.
        bytes32[] tokensIn;
        /// @notice An array of output token addresses expected from the swap.
        /// @dev The resulting tokens must match the tokens stored in `tokensAndAmountsOut`.
        address[] tokensOut;
        /// @notice Minimum acceptable output amounts for each corresponding token in `tokensOut`.
        /// @dev Used for slippage protection; if the output amount is below the corresponding value,
        ///      the transaction reverts.
        uint256[] minAmountsOut;
        /// @notice An array of swap paths for each input token.
        /// @dev Each path is an array of encoded pool descriptors (`bytes32[]`) specifying
        ///      the swap route (Uniswap V2/V3) and associated parameters.
        ///      Length of `pairs` must match length of `tokensIn`.
        bytes32[][] pairs;
    }

    /// @notice Struct containing parameters for a reverse multiswap operation (exact-out).
    /// @dev Used in `multiswapReverse()` to perform a sequence of swaps starting from desired outputs
    ///      and tracing backward to compute and transfer the required inputs.
    struct MultiswapReverseCalldata {
        /// @notice The list of token addresses that can be spent to perform the swaps.
        /// @dev These tokens will be deducted from the contract’s balance or caller's allowance.
        address[] tokensIn;
        /// @notice The desired exact output amounts for each corresponding token in `tokensOut`.
        /// @dev These are target amounts to be received after all swaps.
        uint256[] amountsOut;
        /// @notice The list of tokens to be received as a result of reverse swaps.
        /// @dev These should match the expected outputs and the swap path destinations.
        address[] tokensOut;
        /// @notice Swap paths (in reverse) for each output token in `tokensOut`.
        /// @dev Each path is an array of encoded pool descriptors (`bytes32[]`) that specify
        ///      the swap route from the output token back to an input token.
        bytes32[][] pairs;
    }

    /// @notice Executes multiple sequential swaps based on input tokens and route pairs.
    /// @dev Validates input data, decodes input amounts, and performs multi-hop swaps across defined pairs.
    ///      Collects output tokens and validates minimum output requirements.
    /// @param data The struct containing arrays of input tokens, output tokens, route pairs, and minimum amounts out.
    /// @return tokensAndAmountsOut Array of output tokens and corresponding received amounts encoded as bytes32.
    function multiswap(MultiswapCalldata calldata data) external returns (bytes32[] memory tokensAndAmountsOut);

    /// @notice Executes swaps in reverse order to reach a target output amount.
    /// @dev Useful for exact output swaps. Uses stored amounts to handle remainders and performs final transfers.
    /// @param data The struct including tokens to swap, amounts out, pool pairs, and expected inputs.
    /// @return tokensAndAmountsOut Array of output tokens and corresponding paid amounts encoded as bytes32.
    function multiswapReverse(MultiswapReverseCalldata calldata data)
        external
        returns (bytes32[] memory tokensAndAmountsOut);

    /// @notice Executes multiple swaps from a single input token based on percentage splits.
    /// @dev Uses amountInPercentages to distribute input among swap paths. Verifies all output tokens satisfy minimums.
    /// @param data The struct containing input token, output tokens, pool pairs, percentage splits and min amounts out.
    /// @return tokensAndAmountsOut Array of output tokens and corresponding received amounts encoded as bytes32.
    function multiswap2(Multiswap2Calldata calldata data) external returns (bytes32[] memory tokensAndAmountsOut);
}
