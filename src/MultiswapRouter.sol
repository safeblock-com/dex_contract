// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {HelperLib} from "./libraries/HelperLib.sol";

contract MultiswapRouter {
    bytes private constant _emptyBytes = bytes("");
    uint256 private constant _uniV3Mask =
        0x8000000000000000000000000000000000000000000000000000000000000000;
    address private constant _addressMask =
        0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint256 private constant _feeMask = 0xffffff;

    uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;
    uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970341;

    address private _pairCache;

    struct Calldata {
        uint256 amountIn;
        address tokenIn;
        uint256[] pairs;
    }

    struct CalldataPartswap {
        uint256 fullAmount;
        uint256[] amountsIn;
        address tokenIn;
        uint256[] pairs;
    }

    function multiswap(Calldata calldata data) external {
        uint256 length = data.pairs.length;

        uint256 amountIn = data.amountIn;
        address tokenIn = data.tokenIn;

        HelperLib.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        for (uint256 i; i < length; i = _unfaseIncrement(i)) {
            uint256 pair = data.pairs[i];
            bool uni3;
            assembly {
                uni3 := and(pair, _uniV3Mask)
            }

            if (uni3) {
                (amountIn, tokenIn) = _swapUniV3(pair, amountIn, tokenIn);
            } else {
                (amountIn, tokenIn) = _swapUniV2(pair, amountIn, tokenIn);
            }
        }

        HelperLib.safeTransfer(tokenIn, msg.sender, amountIn);
    }

    function partSwap(CalldataPartswap calldata data) external {
        uint256 length = data.pairs.length;

        address tokenIn = data.tokenIn;

        HelperLib.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            data.fullAmount
        );

        uint256 result;
        address tokenOut;

        for (uint256 i; i < length; i = _unfaseIncrement(i)) {
            uint256 pair = data.pairs[i];
            bool uni3;
            assembly {
                uni3 := and(pair, _uniV3Mask)
            }
            uint256 amountOut;

            if (uni3) {
                (amountOut, tokenOut) = _swapUniV3(
                    pair,
                    data.amountsIn[i],
                    tokenIn
                );
            } else {
                (amountOut, tokenOut) = _swapUniV2(
                    pair,
                    data.amountsIn[i],
                    tokenIn
                );
            }

            result += amountOut;
        }

        HelperLib.safeTransfer(tokenOut, msg.sender, result);
    }

    struct SwapCallbackData {
        address tokenIn;
        address payer;
    }

    // for UniswapV3Callback
    fallback() external {
        int256 amount0Delta;
        int256 amount1Delta;
        bytes calldata _data;

        assembly {
            amount0Delta := calldataload(4)
            amount1Delta := calldataload(24)
            _data.length := calldataload(64)
            _data.offset := 84
        }

        // TODO
        require(msg.sender == _pairCache);
        _pairCache = address(0);

        // swaps entirely within 0-liquidity regions are not supported
        require(amount0Delta > 0 || amount1Delta > 0);
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        uint256 amountToPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        if (data.payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            HelperLib.safeTransfer(data.tokenIn, msg.sender, amountToPay);
        } else {
            // pull payment
            HelperLib.safeTransferFrom(
                data.tokenIn,
                data.payer,
                msg.sender,
                amountToPay
            );
        }
    }

    function _swapUniV3(
        uint256 _pool,
        uint256 amountIn,
        address tokenIn
    ) private returns (uint256, address) {
        IRouter pool;
        uint24 fee;
        assembly {
            pool := and(_pool, _addressMask)
            fee := and(_feeMask, shr(160, _pool))
        }

        address tokenOut = pool.token0();
        if (tokenOut == tokenIn) {
            tokenOut = pool.token1();
        }

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            zeroForOne,
            HelperLib.toInt256(amountIn),
            (zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE),
            abi.encode(tokenIn, address(this))
        );

        return (uint256(-(zeroForOne ? amount1 : amount0)), tokenOut);
    }

    // private functions
    function _swapUniV2(
        uint256 _pair,
        uint256 amountIn,
        address tokenIn
    ) private returns (uint256 amountOut, address tokneOut) {
        IRouter pair;
        uint256 fee;
        assembly {
            pair := and(_pair, _addressMask)
            fee := and(_feeMask, shr(160, _pair))
        }

        HelperLib.safeTransfer(tokenIn, address(pair), amountIn);

        address token0 = pair.token0();
        uint256 amountInput;
        uint256 amountOutput;
        {
            // scope to avoid stack too deep errors
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = tokenIn == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

            amountInput =
                IERC20(tokenIn).balanceOf(address(pair)) -
                reserveInput;

            amountOutput = HelperLib.getAmountOut(
                amountInput,
                reserveInput,
                reserveOutput,
                fee
            );
        }

        (uint256 amount0Out, uint256 amount1Out) = tokenIn == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));

        if (
            !_makeCall(
                address(pair),
                abi.encodeWithSelector(
                    // swap(uint256,uint256,address,bytes) selector
                    0x022c0d9f,
                    amount0Out,
                    amount1Out,
                    address(this),
                    _emptyBytes
                )
            )
        ) {
            if (
                !_makeCall(
                    address(pair),
                    abi.encodeWithSelector(
                        // swap(uint256,uint256,address) selector
                        0x6d9a640a,
                        amount0Out,
                        amount1Out,
                        address(this)
                    )
                )
            ) {
                // TODO
                revert("Multiswap: Failed to swap on UniswapV2 pair");
            }
        }

        return (amountOutput, tokenIn == token0 ? pair.token1() : token0);
    }

    function _unfaseIncrement(uint256 i) private pure returns (uint256) {
        unchecked {
            return ++i;
        }
    }

    function _makeCall(
        address addr,
        bytes memory data
    ) private returns (bool success) {
        (success, ) = addr.call(data);
    }
}
