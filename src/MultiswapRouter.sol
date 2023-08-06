// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {HelperLib} from "./libraries/HelperLib.sol";

contract MultiswapRouter {
    // mask for UniswapV3 pair designation
    // if `mask & pair == true`, the swap is performed using the UniswapV3 logic
    bytes32 private constant UNISWAP_V3_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;
    // address mask: `mask & pair == address(pair)`
    address private constant ADDRESS_MASK =
        0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    // fee mask: `mask & (pair >> 160) == fee in pair`
    uint24 private constant FEE_MASK = 0xffffff;

    // minimum and maximum possible values of SQRT_RATIO in UniswapV3
    uint160 private constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;
    uint160 private constant MAX_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970341;

    // 2**255
    uint256 private constant CAST_INT_CONSTANT =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // address(this) in bytes32 representation
    bytes32 private immutable ADDRESS_THIS_BYTES32;

    // cache for swapV3Callback
    address private _poolAddressCache;

    constructor() {
        bytes32 addressThisBytes32;
        assembly {
            addressThisBytes32 := address()
        }
        ADDRESS_THIS_BYTES32 = addressThisBytes32;
    }

    error MultiswapRouter_FailedV2Swap();

    error MultiswapRouter_InvalidPairsArray();
    error MultiswapRouter_FailedV3Swap();
    error MultiswapRouter_SenderMustBeUniswapV3Pool();
    error MultiswapRouter_InvalidIntCast();

    struct Calldata {
        // initial exact value in
        uint256 amountIn;
        // first token in swap
        address tokenIn;
        // array of bytes32 values (pairs) involved in the swap
        // from left to right:
        //     address of the pair - 20 bytes
        //     fee in pair - 3 bytes
        //     the highest bit shows which version the pair belongs to
        bytes32[] pairs;
    }

    /// @notice Swaps through the data.pairs array
    function multiswap(Calldata calldata data) external {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;

        // if length of array is zero - revert
        if (length == 0) {
            revert MultiswapRouter_InvalidPairsArray();
        }

        bytes32 pair = data.pairs[0];
        address firstPair;
        bool uni3;

        assembly {
            // take the first pair in the array
            firstPair := and(pair, ADDRESS_MASK)
            // find out which version of the protocol it belongs to
            uni3 := and(pair, UNISWAP_V3_MASK)
        }

        uint256 amountIn = data.amountIn;
        address tokenIn = data.tokenIn;

        // execute transferFrom:
        //     if the pair belongs to version 2 of the protocol - to the pair
        //     if version 3 - to the router contract
        HelperLib.safeTransferFrom(
            tokenIn,
            msg.sender,
            uni3 ? address(this) : firstPair,
            amountIn
        );

        bool uni3Next;
        bytes32 destination;
        for (uint256 i; i < length; i = _unsafeAddOne(i)) {
            if (i == length - 1) {
                // if the pair is the last in the array - the next token recipient after the swap is msg.sender
                assembly {
                    destination := caller()
                }
            } else {
                // otherwise take the next pair
                destination = data.pairs[_unsafeAddOne(i)];
            }

            assembly {
                uni3 := and(pair, UNISWAP_V3_MASK)
                // if the next pair belongs to version 3 of the protocol - the address
                // of the router is set as the recipient, otherwise - the next pair
                uni3Next := and(destination, UNISWAP_V3_MASK)
            }

            if (uni3) {
                (amountIn, tokenIn) = _swapUniV3(
                    pair,
                    amountIn,
                    tokenIn,
                    uni3Next ? ADDRESS_THIS_BYTES32 : destination
                );
            } else {
                (amountIn, tokenIn) = _swapUniV2(
                    pair,
                    tokenIn,
                    uni3Next ? ADDRESS_THIS_BYTES32 : destination
                );
            }
            // upgrade the pair for the next swap
            pair = destination;
        }
    }

    struct CalldataPartswap {
        uint256 fullAmount;
        address tokenIn;
        uint256[] amountsIn;
        bytes32[] pairs;
    }

    function partSwap(CalldataPartswap calldata data) external {
        uint256 length = data.pairs.length;
        if (length == 0) {
            revert MultiswapRouter_InvalidPairsArray();
        }

        address tokenIn = data.tokenIn;

        HelperLib.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            data.fullAmount
        );

        bytes32 pair;
        bool uni3;
        bytes32 msgSenderBytes32;
        assembly {
            msgSenderBytes32 := caller()
        }

        for (uint256 i; i < length; i = _unsafeAddOne(i)) {
            pair = data.pairs[i];
            assembly {
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            if (uni3) {
                _swapUniV3(pair, data.amountsIn[i], tokenIn, msgSenderBytes32);
            } else {
                address _pair;
                assembly {
                    _pair := and(pair, ADDRESS_MASK)
                }
                HelperLib.safeTransfer(tokenIn, _pair, data.amountsIn[i]);
                _swapUniV2(pair, tokenIn, msgSenderBytes32);
            }
        }
    }

    // for V3Callback
    fallback() external {
        // Checking that msg.sender is equal to the value from the cache
        // and zeroing the storage
        if (msg.sender != _poolAddressCache) {
            revert MultiswapRouter_SenderMustBeUniswapV3Pool();
        }
        _poolAddressCache = address(0);

        int256 amount0Delta;
        int256 amount1Delta;
        address tokenIn;

        assembly {
            amount0Delta := calldataload(4)
            amount1Delta := calldataload(36)
            tokenIn := calldataload(132)
        }

        // swaps entirely within 0-liquidity regions are not supported
        if (amount0Delta == 0 && amount1Delta == 0) {
            revert MultiswapRouter_FailedV3Swap();
        }

        uint256 amountToPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        // transfer tokens to the pool address
        HelperLib.safeTransfer(tokenIn, msg.sender, amountToPay);
    }

    /// @dev uniswapV3 swap exact tokens
    function _swapUniV3(
        bytes32 _pool,
        uint256 amountIn,
        address tokenIn,
        bytes32 _destination
    ) private returns (uint256 amountOut, address tokenOut) {
        IRouter pool;
        uint24 fee;
        address destination;
        assembly {
            pool := and(_pool, ADDRESS_MASK)
            fee := and(FEE_MASK, shr(160, _pool))
            destination := and(_destination, ADDRESS_MASK)
        }

        // if token0 in the pool is tokenIn - tokenOut == token1, otherwise tokenOut == token0
        tokenOut = pool.token0();
        if (tokenOut == tokenIn) {
            tokenOut = pool.token1();
        }

        bool zeroForOne = tokenIn < tokenOut;

        // cast a uint256 to a int256, revert on overflow
        // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol#L24
        if (!(amountIn < CAST_INT_CONSTANT)) {
            revert MultiswapRouter_InvalidIntCast();
        }

        // caching pool address in storage
        _poolAddressCache = address(pool);
        (int256 amount0, int256 amount1) = pool.swap(
            destination,
            zeroForOne,
            int256(amountIn),
            (zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            abi.encode(tokenIn)
        );

        // return the number of tokens received as a result of the swap
        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @dev uniswapV2 swap exact tokens
    function _swapUniV2(
        bytes32 _pair,
        address tokenIn,
        bytes32 _destination
    ) private returns (uint256 amountOutput, address tokenOut) {
        IRouter pair;
        uint256 fee;
        address destination;
        assembly {
            pair := and(_pair, ADDRESS_MASK)
            fee := and(FEE_MASK, shr(160, _pair))
            destination := and(_destination, ADDRESS_MASK)
        }

        address token0 = pair.token0();
        uint256 amountInput;
        // scope to avoid stack too deep errors
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = tokenIn == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        // get the exact number of tokens that were sent to the pair
        // underflow is impossible cause after token transfer via token contract
        // reserves in the pair not updated yet
        unchecked {
            amountInput =
                IERC20(tokenIn).balanceOf(address(pair)) -
                reserveInput;
        }

        // get the output number of tokens after swap
        amountOutput = HelperLib.getAmountOut(
            amountInput,
            reserveInput,
            reserveOutput,
            fee
        );

        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));

        if (
            // first do the swap via the most common swap function selector
            !_makeCall(
                address(pair),
                abi.encodeWithSelector(
                    // swap(uint256,uint256,address,bytes) selector
                    0x022c0d9f,
                    amount0Out,
                    amount1Out,
                    destination,
                    bytes("")
                )
            )
        ) {
            if (
                // if revert - try to swap through another selector
                !_makeCall(
                    address(pair),
                    abi.encodeWithSelector(
                        // swap(uint256,uint256,address) selector
                        0x6d9a640a,
                        amount0Out,
                        amount1Out,
                        destination
                    )
                )
            ) {
                revert MultiswapRouter_FailedV2Swap();
            }
        }

        tokenOut = tokenIn == token0 ? pair.token1() : token0;
    }

    /// @dev check for overflow has been removed for optimization
    function _unsafeAddOne(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @dev low-level call, returns true if successful
    function _makeCall(
        address addr,
        bytes memory data
    ) private returns (bool success) {
        (success, ) = addr.call(data);
    }
}
