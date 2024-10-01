// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "../proxy/Initializable.sol";
import { UUPSUpgradeable } from "../proxy/UUPSUpgradeable.sol";

import { Ownable2Step } from "../external/Ownable2Step.sol";

import { IUniswapV3Pool } from "../interfaces/IUniswapV3Pool.sol";

import { HelperLib } from "./libraries/HelperLib.sol";
import { HelperV3Lib } from "./libraries/HelperV3Lib.sol";

import { IMultiswapRouterFacet } from "../facets/interfaces/IMultiswapRouterFacet.sol";
import { IWrappedNative } from "../interfaces/IWrappedNative.sol";
import { IRouter } from "../interfaces/IRouter.sol";

import { IFeeContract } from "../interfaces/IFeeContract.sol";

/// @title Multiswap-Partswap Quoter contract
contract Quoter is UUPSUpgradeable, Initializable, Ownable2Step {
    // =========================
    // storage
    // =========================

    /// @dev address of the WrappedNative contract for current chain
    IWrappedNative private immutable _wrappedNative;

    /// @dev mask for UniswapV3 pair designation
    /// if `mask & pair == true`, the swap is performed using the UniswapV3 logic
    bytes32 private constant UNISWAP_V3_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

    /// address mask: `mask & pair == address(pair)`
    address private constant ADDRESS_MASK = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    /// fee mask: `mask & (pair >> 160) == fee in pair`
    uint24 private constant FEE_MASK = 0xffffff;

    IFeeContract private _feeContract;

    // =========================
    // constructor
    // =========================

    constructor(address wrappedNative_) {
        _wrappedNative = IWrappedNative(wrappedNative_);
    }

    function initialize(address newOwner) external initializer {
        _transferOwnership(newOwner);
    }

    function getFeeContract() external view returns (address) {
        return address(_feeContract);
    }

    function setFeeContract(address newFeeContract) external onlyOwner {
        _feeContract = IFeeContract(newFeeContract);
    }

    // =========================
    // main logic
    // =========================

    //// @inheritdoc IMultiswapRouterFacet
    function multiswap(IMultiswapRouterFacet.MultiswapCalldata calldata data) external view returns (uint256 amount) {
        amount = _multiswap(data.tokenIn == address(0), data);

        IFeeContract feeContract = _feeContract;

        if (address(feeContract) > address(0) && amount != type(uint256).max) {
            uint256 fee = feeContract.fees();

            if (fee > 0) {
                unchecked {
                    amount -= amount * fee / 1e6;
                }
            }
        }
    }

    function multiswapReverse(IMultiswapRouterFacet.MultiswapCalldata calldata data)
        external
        view
        returns (uint256 amount)
    {
        amount = _multiswapReverse(data.tokenIn == address(0), data);
    }

    //// @inheritdoc IMultiswapRouterFacet
    function partswap(IMultiswapRouterFacet.PartswapCalldata calldata data) external view returns (uint256 amount) {
        address tokenIn = data.tokenIn;
        uint256 fullAmount = data.fullAmount;

        amount = _partswap(fullAmount, tokenIn == address(0) ? address(_wrappedNative) : tokenIn, data);

        IFeeContract feeContract = _feeContract;

        if (address(feeContract) > address(0) && amount != type(uint256).max) {
            uint256 fee = feeContract.fees();

            if (fee > 0) {
                unchecked {
                    amount -= amount * fee / 1e6;
                }
            }
        }
    }

    // =========================
    // internal methods
    // =========================

    /// @dev Swaps through the data.pairs array
    function _multiswap(
        bool isNative,
        IMultiswapRouterFacet.MultiswapCalldata calldata data
    )
        internal
        view
        returns (uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            return 0;
        }

        address tokenIn;
        uint256 amountIn = data.amountIn;

        assembly ("memory-safe") {
            // find out which version of the protocol it belongs to
        }

        if (isNative) {
            tokenIn = address(_wrappedNative);
        } else {
            tokenIn = data.tokenIn;
        }

        IUniswapV3Pool pool;
        uint256 fee;
        bool uni3;
        bytes32 pair;

        for (uint256 i; i < length;) {
            pair = data.pairs[i];

            assembly ("memory-safe") {
                pool := and(pair, ADDRESS_MASK)
                fee := and(shr(160, pair), FEE_MASK)
                uni3 := and(pair, UNISWAP_V3_MASK)

                i := add(i, 1)

                if iszero(uni3) {
                    amountIn := sub(amountIn, div(mul(amountIn, and(shr(184, pair), FEE_MASK)), 1000000))
                }
            }

            (amountIn, tokenIn) = _quoteExactInput(tokenIn, pool, amountIn, fee, uni3);

            if (amountIn == 0) {
                break;
            }
        }

        return amountIn;
    }

    function _multiswapReverse(
        bool isNative,
        IMultiswapRouterFacet.MultiswapCalldata calldata data
    )
        internal
        view
        returns (uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> revert
        if (length == 0) {
            return 0;
        }

        address tokenOut;
        uint256 amountOut = data.amountIn;

        {
            IFeeContract feeContract = _feeContract;

            if (address(feeContract) > address(0)) {
                uint256 protocolFee = feeContract.fees();

                if (protocolFee > 0) {
                    unchecked {
                        amountOut = amountOut * 1e6 / (1e6 - protocolFee);
                    }
                }
            }
        }

        if (isNative) {
            tokenOut = address(_wrappedNative);
        } else {
            tokenOut = data.tokenIn;
        }

        IUniswapV3Pool pool;
        uint256 fee;
        bool uni3;
        bytes32 pair;

        uint256 index;
        unchecked {
            index = length - 1;
        }

        for (uint256 i; i < length;) {
            pair = data.pairs[index];

            assembly ("memory-safe") {
                pool := and(pair, ADDRESS_MASK)
                fee := and(shr(160, pair), FEE_MASK)
                uni3 := and(pair, UNISWAP_V3_MASK)

                i := add(i, 1)
                index := sub(index, 1)

                if iszero(uni3) {
                    amountOut := add(amountOut, div(mul(amountOut, and(shr(184, pair), FEE_MASK)), 1000000))
                }
            }

            (amountOut, tokenOut) = _quoteExactOutput(tokenOut, pool, amountOut, fee, uni3);

            if (amountOut == type(uint256).max) {
                break;
            }
        }

        return amountOut;
    }

    /// @dev Swaps tokenIn through each pair separately
    function _partswap(
        uint256 fullAmount,
        address tokenIn,
        IMultiswapRouterFacet.PartswapCalldata calldata data
    )
        internal
        view
        returns (uint256)
    {
        // cache length of pairs to stack for gas savings
        uint256 length = data.pairs.length;
        // if length of array is zero -> return 0
        if (length == 0) {
            return 0;
        }
        if (length != data.amountsIn.length) {
            return 0;
        }

        {
            uint256 fullAmountCheck;
            for (uint256 i; i < length;) {
                unchecked {
                    fullAmountCheck += data.amountsIn[i];
                    ++i;
                }
            }

            // sum of amounts array must be lte to fullAmount
            if (fullAmountCheck > fullAmount) {
                return 0;
            }
        }

        uint256 amount;

        IUniswapV3Pool pool;
        uint256 fee;
        bool uni3;
        bytes32 pair;
        uint256 amountOut;

        for (uint256 i; i < length;) {
            pair = data.pairs[i];

            assembly ("memory-safe") {
                pool := and(pair, ADDRESS_MASK)
                fee := and(shr(160, pair), FEE_MASK)
                uni3 := and(pair, UNISWAP_V3_MASK)
            }

            (amountOut,) = _quoteExactInput(tokenIn, pool, data.amountsIn[i], fee, uni3);

            unchecked {
                amount += amountOut;
                ++i;
            }
        }

        return amount;
    }

    function _quoteExactInput(
        address tokenIn,
        IUniswapV3Pool pool,
        uint256 amountIn,
        uint256 fee,
        bool uni3
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

                (, amountOut) = HelperV3Lib.quoteV3({ pool: pool, zeroForOne: zeroForOne, amountSpecified: amount });
            } else {
                try pool.getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
                    (uint256 reserveInput, uint256 reserveOutput) =
                        tokenIn == _token0 ? (reserve0, reserve1) : (reserve1, reserve0);

                    amountOut = HelperLib.getAmountOut({
                        amountIn: amountIn,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: fee
                    });
                } catch {
                    return (0, address(0));
                }
            }
        }
    }

    function _quoteExactOutput(
        address tokenOut,
        IUniswapV3Pool pool,
        uint256 amountOut,
        uint256 fee,
        bool uni3
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

                (amountIn,) = HelperV3Lib.quoteV3({ pool: pool, zeroForOne: zeroForOne, amountSpecified: -amount });
            } else {
                try pool.getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
                    (uint256 reserveInput, uint256 reserveOutput) =
                        tokenIn == _token0 ? (reserve0, reserve1) : (reserve1, reserve0);

                    amountIn = HelperLib.getAmountIn({
                        amountOut: amountOut,
                        reserveIn: reserveInput,
                        reserveOut: reserveOutput,
                        feeE6: fee
                    });
                } catch {
                    return (type(uint256).max, address(0));
                }
            }
        }
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
