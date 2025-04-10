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
        bytes32 pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR3))));
        assembly {
            pair := add(pair, shl(184, 1))
        }

        address tokenIn = SOLIDLY_PAIR3.token0();
        address tokenOut = SOLIDLY_PAIR3.token1();

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = tokenIn;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        deal({ token: tokenIn, to: user, give: 100e18 });

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = quoterAmountOut;

        _resetPrank(user);
        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR2.token0();
        tokenOut = SOLIDLY_PAIR2.token1();

        deal({ token: tokenIn, to: user, give: 100e18 });

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR2))));
        assembly {
            pair := add(pair, shl(184, 1))
        }

        m2Data.fullAmount = 10e18;
        m2Data.tokenIn = tokenIn;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = quoterAmountOut;

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR1.token0();
        tokenOut = SOLIDLY_PAIR1.token1();

        deal({ token: tokenIn, to: user, give: 100e18 });

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR1))));
        assembly {
            pair := add(pair, shl(184, 1))
        }

        m2Data.fullAmount = 100e18;
        m2Data.tokenIn = tokenIn;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = quoterAmountOut;

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }
}
