// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IMultiswapRouterFacet,
    TransferFacet,
    IUniswapPool,
    PoolHelper,
    console2
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract MultiswapSolidlyTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("optimism_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });
        quoter.setRouter({ router: address(entryPoint) });
    }

    // =========================
    // multiswap
    // =========================

    function test_multiswapRouterFacet_multiswap2_solidlyPairs() external {
        _resetPrank(user);

        bytes32 pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR3))));

        uint256 fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR3) });

        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        address tokenIn = SOLIDLY_PAIR3.token1();
        address tokenOut = SOLIDLY_PAIR3.token0();

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = tokenIn;
        m2Data.fullAmount = 100 * 10 ** IERC20(tokenIn).decimals();
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        deal({ token: tokenIn, to: user, give: m2Data.fullAmount });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(m2Data.tokensOut[0], user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR2.token0();
        tokenOut = SOLIDLY_PAIR2.token1();

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR2))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR2) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        m2Data.tokenIn = tokenIn;
        m2Data.fullAmount = 100 * 10 ** IERC20(tokenIn).decimals();
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        deal({ token: tokenIn, to: user, give: m2Data.fullAmount });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(m2Data.tokensOut[0], user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR1.token0();
        tokenOut = SOLIDLY_PAIR1.token1();

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR1))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR1) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        m2Data.tokenIn = tokenIn;
        m2Data.fullAmount = 100 * 10 ** IERC20(tokenIn).decimals();
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        deal({ token: tokenIn, to: user, give: m2Data.fullAmount });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(m2Data.tokensOut[0], user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    // =========================
    // multiswapReverse
    // =========================

    function test_multiswapRouterFacet_multiswap2Reverse_solidlyPairs() external {
        _resetPrank(user);

        bytes32 pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR3))));
        uint256 fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR3) });

        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        address tokenIn = SOLIDLY_PAIR3.token1();
        address tokenOut = SOLIDLY_PAIR3.token0();

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = tokenIn;
        m2Data.minAmountsOut = Solarray.uint256s(10 ** IERC20(tokenOut).decimals());
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(tokenOut)));
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: tokenIn, to: user, give: m2Data.fullAmount });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(m2Data.tokensOut[0], user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR2.token0();
        tokenOut = SOLIDLY_PAIR2.token1();

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR2))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR2) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        m2Data.tokenIn = tokenIn;
        m2Data.minAmountsOut = Solarray.uint256s(10 ** IERC20(tokenOut).decimals());
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(tokenOut)));
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        (, bytes memory data) = address(SOLIDLY_PAIR2).staticcall(
            abi.encodeWithSignature(
                "getAmountOut(uint256,address)", m2Data.fullAmount - m2Data.fullAmount * 300 / 1e6, tokenIn
            )
        );
        console2.log("exactAmountIn", abi.decode(data, (uint256)));

        deal({ token: tokenIn, to: user, give: m2Data.fullAmount });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(m2Data.tokensOut[0], user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR1.token0();
        tokenOut = SOLIDLY_PAIR1.token1();

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR1))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR1) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        m2Data.tokenIn = tokenIn;
        m2Data.minAmountsOut = Solarray.uint256s(10 ** IERC20(tokenOut).decimals());
        m2Data.amountInPercentages = Solarray.uint256s(uint256(uint160(tokenOut)));
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));
        m2Data.tokensOut = Solarray.addresses(tokenOut);

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });

        deal({ token: tokenIn, to: user, give: m2Data.fullAmount });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: m2Data.fullAmount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), m2Data.fullAmount);
        _expectERC20TransferCall(m2Data.tokensOut[0], user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2Reverse, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }
}
