// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "../proxy/Initializable.sol";
import { UUPSUpgradeable } from "../proxy/UUPSUpgradeable.sol";

import { Ownable2Step } from "../external/Ownable2Step.sol";

import { IUniswapPool } from "../facets/multiswapRouterFacet/interfaces/IUniswapPool.sol";

import { HelperV2Lib } from "./libraries/HelperV2Lib.sol";
import { HelperV3Lib, TickMath } from "./libraries/HelperV3Lib.sol";

import { IMultiswapRouterFacet } from "../facets/multiswapRouterFacet/interfaces/IMultiswapRouterFacet.sol";

import { IEntryPoint } from "../interfaces/IEntryPoint.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { E18, UNISWAP_V3_MASK, ADDRESS_MASK, FEE_MASK, E6 } from "../libraries/Constants.sol";

import { EfficientSwapAmount } from "./libraries/EfficientSwapAmount.sol";

import { PoolHelper } from "../libraries/PoolHelper.sol";

/// @title Multiswap-Partswap Quoter contract
contract Quoter is UUPSUpgradeable, Initializable, Ownable2Step {
    // =========================
    // storage
    // =========================

    /// @dev address of the WrappedNative contract for current chain
    address private immutable _wrappedNative;

    IEntryPoint private _router;

    // =========================
    // constructor
    // =========================

    constructor(address wrappedNative_) {
        _wrappedNative = wrappedNative_;
    }

    function initialize(address newOwner) external initializer {
        _transferOwnership(newOwner);
    }

    function getRouter() external view returns (address) {
        return address(_router);
    }

    function setRouter(address router) external onlyOwner {
        _router = IEntryPoint(router);
    }

    function getPoolFee(address pair) external view returns (uint256) {
        (,, bool stableSwap) =
            PoolHelper.getReserves({ pair: IUniswapPool(pair), tokenInIsToken0: true, isSolidly: true });

        return PoolHelper.getFee({ pair: IUniswapPool(pair), stableSwap: stableSwap });
    }

    // =========================
    // main logic
    // =========================

    function efficientAmounts2(
        bytes32 pair,
        address tokenIn,
        uint256 targetPrice
    )
        external
        view
        returns (uint256 amountIn)
    {
        (bool uni3, IUniswapPool pool, uint256 isSolidly, uint256 fee) = _getPoolInfo(pair);

        if (uni3) {
            amountIn =
                EfficientSwapAmount.efficientV3Amounts2({ pool: pool, tokenIn: tokenIn, targetPrice: targetPrice });
        } else {
            amountIn = EfficientSwapAmount.efficientV2Amounts2({
                pair: pool,
                tokenIn: tokenIn,
                targetPrice: targetPrice,
                feeE6: fee,
                isSolidly: isSolidly > 0
            });
        }
    }

    //// @inheritdoc IMultiswapRouterFacet
    function multiswap(IMultiswapRouterFacet.MultiswapCalldata calldata data)
        external
        view
        returns (uint256 amountOut)
    {
        (amountOut,) =
            _multiswap(data.pairs, _subFee(data.amountIn), data.tokenIn == address(0) ? _wrappedNative : data.tokenIn);
    }

    function multiswapReverse(IMultiswapRouterFacet.MultiswapCalldata calldata data)
        external
        view
        returns (uint256 amountOut)
    {
        amountOut = _addFee(_multiswapReverse(data.pairs, data.amountIn, data.tokenIn));
    }

    //// @inheritdoc IMultiswapRouterFacet
    function multiswap2(IMultiswapRouterFacet.Multiswap2Calldata calldata data)
        external
        view
        returns (uint256[] memory amountsOut)
    {
        amountsOut = new uint256[](data.tokensOut.length);

        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            return amountsOut;
        }
        if (length != data.amountInPercentages.length) {
            return amountsOut;
        }

        address[] calldata tokensOut = data.tokensOut;

        uint256 fullAmount = _subFee(data.fullAmount);
        address tokenIn = data.tokenIn == address(0) ? _wrappedNative : data.tokenIn;

        {
            uint256 amountInPercentagesCheck;
            for (uint256 i; i < length;) {
                unchecked {
                    amountInPercentagesCheck += data.amountInPercentages[i];
                    ++i;
                }
            }

            // sum of amounts array must be equal to 100% (1e18)
            if (amountInPercentagesCheck != E18) {
                return amountsOut;
            }
        }

        {
            uint256 lastIndex;
            unchecked {
                lastIndex = length - 1;
            }

            uint256 remainingAmount = fullAmount;
            uint256 amountIn;
            for (uint256 i; i < length;) {
                if (i == lastIndex) {
                    amountIn = remainingAmount;
                } else {
                    unchecked {
                        amountIn = fullAmount * data.amountInPercentages[i] / E18;
                        remainingAmount -= amountIn;
                    }
                }

                (uint256 _amountOut, address _tokenOut) = _multiswap(data.pairs[i], amountIn, tokenIn);

                bool added;
                for (uint256 j = tokensOut.length; j > 0;) {
                    unchecked {
                        --j;

                        if (tokensOut[j] == _tokenOut) {
                            amountsOut[j] += _amountOut;
                            added = true;
                            break;
                        }
                    }
                }
                if (!added) {
                    return new uint256[](tokensOut.length);
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    function multiswap2Reverse(IMultiswapRouterFacet.Multiswap2Calldata calldata data)
        external
        view
        returns (uint256 amountIn)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            return type(uint256).max;
        }
        if (length != data.tokensOut.length) {
            return type(uint256).max;
        }

        address[] memory tokensOut;
        {
            uint256 amountInPercentagesLength = data.amountInPercentages.length;
            if (amountInPercentagesLength == 0) {
                revert IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata();
            }
            tokensOut = new address[](amountInPercentagesLength);
            for (uint256 i; i < amountInPercentagesLength;) {
                // TODO optimize
                tokensOut[i] = address(uint160(data.amountInPercentages[i]));

                unchecked {
                    ++i;
                }
            }
        }

        {
            for (uint256 i; i < length;) {
                address tokenOut = data.tokensOut[i];

                uint256 _amountIn = _multiswapReverse(data.pairs[i], data.minAmountsOut[i], tokenOut);

                if (_amountIn == type(uint256).max) {
                    return _amountIn;
                }

                unchecked {
                    amountIn += _amountIn;

                    bool added;
                    for (uint256 j = tokensOut.length; j > 0;) {
                        --j;
                        if (tokensOut[j] == tokenOut) {
                            // amountsOut[j] += _amountOut;
                            added = true;
                            break;
                        }
                    }
                    if (!added) {
                        return type(uint256).max;
                    }
                    ++i;
                }
            }
        }

        amountIn = _addFee(amountIn);
    }

    // =========================
    // internal methods
    // =========================

    /// @dev Swaps through the data.pairs array
    function _multiswap(
        bytes32[] calldata pairs,
        uint256 amountIn,
        address tokenIn
    )
        internal
        view
        returns (uint256, address)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            return (0, address(0));
        }

        IUniswapPool pool;
        uint256 fee;
        uint256 isSolidly;
        bool uni3;

        for (uint256 i; i < length;) {
            (uni3, pool, isSolidly, fee) = _getPoolInfo(pairs[i]);

            unchecked {
                ++i;
            }

            (amountIn, tokenIn) = _quoteExactInput(uni3, tokenIn, pool, isSolidly, amountIn, fee);

            if (amountIn == 0) {
                break;
            }
        }

        return (amountIn, tokenIn);
    }

    function _multiswapReverse(
        bytes32[] calldata pairs,
        uint256 amountOut,
        address tokenOut
    )
        internal
        view
        returns (uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = pairs.length;
        // if length of array is zero -> return invalid value
        if (length == 0) {
            return amountOut;
        }

        IUniswapPool pool;
        uint256 fee;
        bool uni3;
        uint256 isSolidly;

        for (; length > 0;) {
            unchecked {
                --length;
            }

            (uni3, pool, isSolidly, fee) = _getPoolInfo(pairs[length]);

            (amountOut, tokenOut) = _quoteExactOutput(uni3, tokenOut, pool, isSolidly, amountOut, fee);

            if (amountOut == type(uint256).max) {
                break;
            }
        }

        return amountOut;
    }

    function _quoteExactInput(
        bool uni3,
        address tokenIn,
        IUniswapPool pool,
        uint256 isSolidly,
        uint256 amountIn,
        uint256 fee
    )
        internal
        view
        returns (uint256 amountOut, address tokenOut)
    {
        address _token0;
        try pool.token0() returns (address token0) {
            _token0 = token0;
            tokenOut = token0;
            if (tokenOut == tokenIn) {
                tokenOut = pool.token1();
            }
        } catch {
            return (0, address(0));
        }

        if (tokenOut > address(0) && tokenIn > address(0)) {
            if (uni3) {
                bool zeroForOne = tokenIn < tokenOut;

                int256 amount;
                assembly ("memory-safe") {
                    amount := amountIn
                }

                unchecked {
                    (, amountOut) = HelperV3Lib.quoteV3({
                        pool: pool,
                        zeroForOne: zeroForOne,
                        amountSpecified: amount,
                        sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1
                    });
                }
            } else {
                uint256 reserveInput;
                uint256 reserveOutput;
                bool stableSwap;
                (reserveInput, reserveOutput, stableSwap) = PoolHelper.getReserves({
                    pair: pool,
                    tokenInIsToken0: tokenIn == _token0,
                    isSolidly: isSolidly > 0
                });

                if (stableSwap) {
                    amountOut = HelperV2Lib.stableAmountOut({
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        amountIn: amountIn,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: fee
                    });
                } else {
                    amountOut = HelperV2Lib.volatileAmountOut({
                        amountIn: amountIn,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: fee
                    });
                }
            }
        }
    }

    function _quoteExactOutput(
        bool uni3,
        address tokenOut,
        IUniswapPool pool,
        uint256 isSolidly,
        uint256 amountOut,
        uint256 fee
    )
        internal
        view
        returns (uint256 amountIn, address tokenIn)
    {
        address _token0;
        try pool.token0() returns (address token0) {
            _token0 = token0;
            tokenIn = token0;
            if (tokenOut == tokenIn) {
                tokenIn = pool.token1();
            }
        } catch {
            return (type(uint256).max, address(0));
        }

        if (tokenOut > address(0) && tokenIn > address(0)) {
            if (uni3) {
                bool zeroForOne = tokenIn < tokenOut;

                int256 amount;
                assembly ("memory-safe") {
                    amount := amountOut
                }
                unchecked {
                    (amountIn,) = HelperV3Lib.quoteV3({
                        pool: pool,
                        zeroForOne: zeroForOne,
                        amountSpecified: -amount,
                        sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1
                    });
                }
            } else {
                (uint256 reserveInput, uint256 reserveOutput, bool stableSwap) = PoolHelper.getReserves({
                    pair: pool,
                    tokenInIsToken0: tokenIn == _token0,
                    isSolidly: isSolidly > 0
                });

                if (stableSwap) {
                    amountIn = HelperV2Lib.stableAmountIn({
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        amountOut: amountOut,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: fee
                    });
                } else {
                    amountIn = HelperV2Lib.volatileAmountIn({
                        amountOut: amountOut,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: fee
                    });
                }
            }
        }
    }

    function _getPoolInfo(bytes32 bytes32Pool)
        private
        pure
        returns (bool uni3, IUniswapPool pool, uint256 isSolidly, uint256 fee)
    {
        assembly ("memory-safe") {
            pool := and(bytes32Pool, ADDRESS_MASK)
            fee := and(shr(160, bytes32Pool), FEE_MASK)
            uni3 := and(bytes32Pool, UNISWAP_V3_MASK)
            isSolidly := and(shr(184, bytes32Pool), 0xff)
        }
    }

    function _subFee(uint256 amount) private view returns (uint256) {
        if (address(_router) > address(0)) {
            (, uint256 protocolFee) = _router.getFeeContractAddressAndFee();

            if (protocolFee > 0 && amount != 0) {
                unchecked {
                    return amount - amount * protocolFee / E6;
                }
            }
        }
        return amount;
    }

    function _addFee(uint256 amount) private view returns (uint256) {
        if (address(_router) > address(0)) {
            (, uint256 protocolFee) = _router.getFeeContractAddressAndFee();

            if (protocolFee > 0) {
                unchecked {
                    amount = amount * (E6 + protocolFee) / E6;
                }
            }
        }
        return amount;
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    ///
    /// Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
    ///
    /// ```solidity
    /// function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
