// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BaseTest, IERC20, Solarray, IMultiswapRouterFacet, TransferFacet } from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract MultiswapSolidlyTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("optimism_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();
    }

    // =========================
    // multiswap
    // =========================

    function test_multiswapRouterFacet_multiswap_solidly() external {
        ISolidlyPair solidlyFactory = ISolidlyPair(SOLIDLY_PAIR3.factory());

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        address tokenIn = SOLIDLY_PAIR3.token0();
        address tokenOut = SOLIDLY_PAIR3.token1();

        deal({ token: tokenIn, to: user, give: 100e18 });

        bool stable = SOLIDLY_PAIR3.stable();
        uint256 fee = solidlyFactory.getFee(address(SOLIDLY_PAIR3), stable) * 100;

        bytes32 pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR3))));
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        mData.amountIn = 100e18;
        mData.tokenIn = tokenIn;
        mData.pairs = Solarray.bytes32s(pair);

        uint256 quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);
        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR2.token0();
        tokenOut = SOLIDLY_PAIR2.token1();

        deal({ token: tokenIn, to: user, give: 100e18 });

        stable = SOLIDLY_PAIR2.stable();
        fee = solidlyFactory.getFee(address(SOLIDLY_PAIR2), stable) * 100;

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR2))));
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        mData.amountIn = 10e18;
        mData.tokenIn = tokenIn;
        mData.pairs = Solarray.bytes32s(pair);

        quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR1.token0();
        tokenOut = SOLIDLY_PAIR1.token1();

        deal({ token: tokenIn, to: user, give: 100e18 });

        stable = SOLIDLY_PAIR1.stable();
        fee = solidlyFactory.getFee(address(SOLIDLY_PAIR1), stable) * 100;

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR1))));
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        mData.amountIn = 100e18;
        mData.tokenIn = tokenIn;
        mData.pairs = Solarray.bytes32s(pair);

        quoterAmountOut = quoter.multiswap({ data: mData });

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }
}
