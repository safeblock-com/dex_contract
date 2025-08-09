// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

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

    function test_multiswapRouterFacet_multiswap_solidlyPairs() external {
        _resetPrank(user);

        bytes32 pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR3))));

        uint256 fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR3) });

        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        address tokenIn = SOLIDLY_PAIR3.token1();
        address tokenOut = SOLIDLY_PAIR3.token0();

        uint256 amount = 100 * 10 ** IERC20(tokenIn).decimals();

        deal({ token: tokenIn, to: user, give: amount });

        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: tokenIn, amount: 1 }));
        mData.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool({ pool: pair, percentage: 1e18 })));
        mData.tokensOut = Solarray.addresses(tokenOut);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(tokenIn), amounts: Solarray.uint256s(amount) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: amount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), amount);
        _expectERC20TransferCall(mData.tokensOut[0], user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR2.token0();
        tokenOut = SOLIDLY_PAIR2.token1();

        amount = 1000 * 10 ** IERC20(tokenIn).decimals();
        deal({ token: tokenIn, to: user, give: amount });

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR2))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR2) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: tokenIn, amount: 1 }));
        mData.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool({ pool: pair, percentage: 1e18 })));
        mData.tokensOut = Solarray.addresses(tokenOut);

        tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(tokenIn), amounts: Solarray.uint256s(amount) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: amount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), amount);
        _expectERC20TransferCall(mData.tokensOut[0], user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });

        // ================================================================================

        tokenIn = SOLIDLY_PAIR1.token0();
        tokenOut = SOLIDLY_PAIR1.token1();

        amount = 100 * 10 ** IERC20(tokenIn).decimals();
        deal({ token: tokenIn, to: user, give: amount });

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR1))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR1) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: tokenIn, amount: 1 }));
        mData.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool({ pool: pair, percentage: 1e18 })));
        mData.tokensOut = Solarray.addresses(tokenOut);

        tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(tokenIn), amounts: Solarray.uint256s(amount) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: amount });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), amount);
        _expectERC20TransferCall(mData.tokensOut[0], user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    // =========================
    // multiswapReverse
    // =========================

    function test_multiswapRouterFacet_multiswapReverse_solidlyPairs() external {
        _resetPrank(user);

        bytes32 pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR3))));
        uint256 fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR3) });

        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        address tokenIn = SOLIDLY_PAIR3.token1();
        address tokenOut = SOLIDLY_PAIR3.token0();

        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(tokenIn);
        mRData.amountsOut = Solarray.uint256s(10 ** IERC20(tokenOut).decimals());
        mRData.tokensOut = Solarray.addresses(tokenOut);
        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: tokenIn, to: user, give: amountsIn[0] });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(mRData.tokensOut[0], user, mRData.amountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mRData.tokensOut))
            )
        });

        // ================================================================================

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR2))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR2) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        tokenIn = SOLIDLY_PAIR2.token0();
        tokenOut = SOLIDLY_PAIR2.token1();

        mRData.tokensIn = Solarray.addresses(tokenIn);
        mRData.amountsOut = Solarray.uint256s(10 ** IERC20(tokenOut).decimals());
        mRData.tokensOut = Solarray.addresses(tokenOut);
        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));

        (tokensIn, amountsIn) = quoter.multiswapReverse({ data: mRData });

        tokenTransfers = IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: tokenIn, to: user, give: amountsIn[0] });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(mRData.tokensOut[0], user, mRData.amountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mRData.tokensOut))
            )
        });

        // ================================================================================

        pair = bytes32(uint256(uint160(address(SOLIDLY_PAIR1))));
        fee = quoter.getPoolFee({ pair: address(SOLIDLY_PAIR1) });
        assembly {
            pair := add(pair, add(shl(160, fee), shl(184, 1)))
        }

        tokenIn = SOLIDLY_PAIR1.token0();
        tokenOut = SOLIDLY_PAIR1.token1();

        mRData.tokensIn = Solarray.addresses(tokenIn);
        mRData.amountsOut = Solarray.uint256s(10 ** IERC20(tokenOut).decimals());
        mRData.tokensOut = Solarray.addresses(tokenOut);
        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(pair));

        (tokensIn, amountsIn) = quoter.multiswapReverse({ data: mRData });

        tokenTransfers = IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: tokenIn, to: user, give: amountsIn[0] });

        IERC20(tokenIn).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(tokenIn, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(mRData.tokensOut[0], user, mRData.amountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mRData.tokensOut))
            )
        });
    }
}
