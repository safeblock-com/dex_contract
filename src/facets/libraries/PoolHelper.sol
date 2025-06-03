// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "../../interfaces/IUniswapPool.sol";

import { E6 } from "../../libraries/Constants.sol";

/// @title PoolHelper
library PoolHelper {
    // =========================
    // helper methods
    // =========================

    /// @dev check if tokenIn is token0 or token1 and return tokenOut
    function validateTokenInPair(IUniswapPool pool, address token) internal view returns (bool, address) {
        address token0 = pool.token0();
        // if token0 in the pair is tokenIn -> tokenOut == token1, otherwise tokenOut == token0
        if (token0 == token) {
            return (true, pool.token1());
        } else {
            return (false, token0);
        }
    }

    /// @dev return reserve of tokenIn and tokenOut in UniswapV2 pair
    function getReserves(
        bool tokenInIsToken0,
        bool isSolidly,
        IUniswapPool pair
    )
        internal
        view
        returns (uint256 reserveInput, uint256 reserveOutput, bool stableSwap)
    {
        uint256 reserve0;
        uint256 reserve1;

        unchecked {
            if (isSolidly) {
                try pair.metadata() returns (uint256, uint256, uint256 r0, uint256 r1, bool st, address, address) {
                    reserve0 = r0;
                    reserve1 = r1;
                    stableSwap = st;
                } catch {
                    (, bytes memory data) = address(pair).staticcall(abi.encodeWithSignature("getReserves()"));
                    uint256 feeToken0;
                    uint256 feeToken1;
                    (reserve0, reserve1, feeToken0, feeToken1) = abi.decode(data, (uint256, uint256, uint256, uint256));
                    stableSwap = pair.stableSwap();
                }
            } else {
                (reserve0, reserve1,) = pair.getReserves();
            }
        }

        (reserveInput, reserveOutput) = tokenInIsToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getFee(IUniswapPool pair, bool stableSwap) internal view returns (uint256 feeE6) {
        (bool success, bytes memory data) = address(pair).staticcall(abi.encodeWithSignature("feeRatio()"));

        if (success) {
            feeE6 = abi.decode(data, (uint256));
        } else {
            (success, data) = address(pair).staticcall(abi.encodeWithSignature("swapFee()"));

            if (success) {
                feeE6 = abi.decode(data, (uint256)) * 100;
            } else {
                (success, data) = address(pair).staticcall(abi.encodeWithSignature("pairFee()"));

                if (success) {
                    feeE6 = abi.decode(data, (uint256)) / 1_000_000_000_000;
                } else {
                    (success, data) = address(pair).staticcall(abi.encodeWithSignature("factory()"));

                    if (success) {
                        address factory = abi.decode(data, (address));

                        (success, data) =
                            address(factory).staticcall(abi.encodeWithSignature("getFee(bool)", stableSwap));

                        if (success) {
                            feeE6 = abi.decode(data, (uint256)) * 100;
                        } else {
                            (success, data) = address(factory).staticcall(
                                abi.encodeWithSignature("getFee(address,bool)", pair, stableSwap)
                            );

                            if (success) {
                                feeE6 = abi.decode(data, (uint256)) * 100;
                            } else {
                                (success, data) =
                                    address(factory).staticcall(abi.encodeWithSignature("getFee(address)", pair));

                                if (success) {
                                    feeE6 = abi.decode(data, (uint256)) * 100;
                                } else {
                                    feeE6 = 500;
                                }
                            }
                        }
                    } else {
                        if (stableSwap) {
                            feeE6 = 300;
                        } else {
                            feeE6 = 2500;
                        }
                    }
                }
            }
        }
    }
}
