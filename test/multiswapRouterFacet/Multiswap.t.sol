// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract MultiswapTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ token: USDC, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });
    }

    // =========================
    // constructor
    // =========================

    function test_multiswapRouterFacet_constructor_shouldInitializeInConstructor() external {
        new MultiswapRouterFacet();

        new TransferFacet({ wrappedNative: contracts.wrappedNative, permit2: contracts.permit2 });
    }

    // =========================
    // multiswap
    // =========================

    function test_multiswapRouterFacet_multiswap_shouldRevertWithoutMulticall() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)));
        mData.minAmountsOut = Solarray.uint256s(0);

        vm.expectRevert();
        MultiswapRouterFacet(address(entryPoint)).multiswap({ data: mData });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokensInArrayIsEmpty() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensOut = Solarray.addresses(WBNB);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)));
        mData.minAmountsOut = Solarray.uint256s(0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokensInArrayLengthIsNotEqualToPairsArrayLength()
        external
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.minAmountsOut = Solarray.uint256s(0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });

        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18))
        );

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokensOutArrayIsEmpty() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = new address[](0);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)));
        mData.minAmountsOut = Solarray.uint256s(0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokensOutArrayLengthIsNotEqualToMinAmountsOutArrayLength(
    )
        external
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)));

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });

        mData.tokensOut = Solarray.addresses(WBNB, USDC);
        mData.minAmountsOut = Solarray.uint256s(0);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokensOutArrayNotUnique() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(WBNB, WBNB);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)));
        mData.minAmountsOut = Solarray.uint256s(0, 0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });

        mData.tokensOut = Solarray.addresses(WBNB, USDC, WBNB);
        mData.minAmountsOut = Solarray.uint256s(0, 0, 0);

        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });

        mData.tokensOut = Solarray.addresses(USDC, WBNB, WBNB);
        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokenIndexIsInvalid() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 0 }));
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_CakeV3_100, 1e18)));
        mData.minAmountsOut = Solarray.uint256s(0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1e18, 1e18)
        });

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });

        // 1 after 2
        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 }),
            Utils.encodeTokenAndAmount({ token: WBNB, amount: 1 })
        );
        mData.tokensOut = Solarray.addresses(CAKE);
        mData.minAmountsOut = Solarray.uint256s(0);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_UniV3_3000, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Cake, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(USDT_CAKE_Cake, 1e18))
        );

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 1, 2));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfAmountInIsZero() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.tokensOut = Solarray.addresses(CAKE);
        mData.minAmountsOut = Solarray.uint256s(0);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_UniV3_3000, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Cake, 1e18))
        );

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfArrayNotEmptyAfterSwap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1e18, 1e18)
        });

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.minAmountsOut = Solarray.uint256s(0);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_UniV3_3000, 1e18)));

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldSwap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 }),
            Utils.encodeTokenAndAmount({ token: USDT, amount: 2 }),
            Utils.encodeTokenAndAmount({ token: CAKE, amount: 2 })
        );
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_CakeV3_100, 0.1e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.9e18)
            ),
            Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Cake, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(USDT_CAKE_Cake, 1e18)),
            Solarray.bytes32s(_encodePercentageInPool(WBNB_CAKE_UniV3_3000, 1e18))
        );

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(100e18, 100e18)
        });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 100e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    function test_multiswapRouterFacet_failedV3Swap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDC, amount: 1 }));
        mData.tokensOut = Solarray.addresses(CAKE);
        mData.minAmountsOut = Solarray.uint256s(0);
        mData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(_encodePercentageInPool(USDC_CAKE_UniV3_500, 1e18)));

        _resetPrank(user);
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 100e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(100e18) });

        vm.expectRevert(IErrors.MultiswapRouterFacet_FailedV3Swap.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_failedV2Swap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.minAmountsOut = Solarray.uint256s(0);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(0x0000000000000000000009c016b9a82891338f9bA80E2D6970FddA79D1eb0daE, 1e18)
            )
        );

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.MultiswapRouterFacet_FailedV2Swap.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_failedCallback() external {
        (, bytes memory data) =
            contracts.multiswapRouterFacet.call(abi.encodeWithSelector(TransferFacet.transferToken.selector));

        assertEq(bytes4(data), IErrors.MultiswapRouterFacet_SenderMustBePool.selector);
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapThroughAllUniswapV2Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.tokensOut = Solarray.addresses(USDC);
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_USDC_Biswap, 0.25e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.25e18),
                _encodePercentageInPool(USDT_USDC_Cake, 0.25e18)
            )
        );

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapThroughAllUniswapV3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfTokenNotTransferredFromContract()
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);
        mData.minAmountsOut = Solarray.uint256s(0);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)))
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfAmountOutLtMinAmountOut() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_3000, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.25e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        mData.minAmountsOut =
            Solarray.uint256s(quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData })[0] + 1);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(
            abi.encodeWithSelector(
                IErrors.ValueLowerThanExpected.selector, mData.minAmountsOut[0] - 1, mData.minAmountsOut[0]
            )
        );
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_partswapNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        deal({ to: user, give: 10e18 });

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: WBNB, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_ETH_Cake, 0.1e18),
                _encodePercentageInPool(WBNB_ETH_UniV3_500, 0.2e18),
                _encodePercentageInPool(WBNB_ETH_UniV3_3000, 0.3e18),
                _encodePercentageInPool(WBNB_ETH_CakeV3_500, 0.3e18),
                _encodePercentageInPool(WBNB_ETH_Bakery, 0.1e18)
            )
        );
        mData.tokensOut = Solarray.addresses(ETH);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(address(0)), amounts: Solarray.uint256s(10e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        _expectERC20TransferCall(ETH, user, mData.minAmountsOut[0]);
        entryPoint.multicall{ value: 10e18 }({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    // address constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;

    // function test_multiswapRouterFacet_multiswap_partswapThroughV2V3Pairs() external checkStorage {
    //     IMultiswapRouterFacet.MultiswapCalldata memory mData;

    //     deal({ token: USDT, to: user, give: 10e18 });

    //     mData.tokensIn = Solarray.bytes32s(
    //         Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
    //         Utils.encodeTokenAndAmount({ token: USDC, amount: 1 })
    //     );
    //     mData.pairs = Solarray.bytes32Arrays(
    //         Solarray.bytes32s(
    //             _encodePercentageInPool(0x800000000000000000000064efcb55270c5fe85fc8eb6a311dc5aa9479839f0d, 1e18)
    //         ),
    //         Solarray.bytes32s(
    //             _encodePercentageInPool(0x8000000000000000000000647a72b31918f598154f3e6171c5f341fbaf1fd0b7, 0.5e18),
    //             _encodePercentageInPool(bytes32(0), 0.5e18)
    //         )
    //     );
    //     mData.tokensOut = Solarray.addresses(USDC, DAI);

    //     IEntryPoint.TokenTransfers memory tokenTransfers =
    //         IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(10e18) });

    //     // mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });
    //     mData.minAmountsOut = Solarray.uint256s(0, 0);

    //     _resetPrank(user);

    //     IERC20(USDT).approve({ spender: address(entryPoint), amount: 10e18 });

    //     // _expectERC20TransferCall(ETH, user, mData.minAmountsOut[0]);
    //     entryPoint.multicall({
    //         tokenTransfers: tokenTransfers,
    //         data: Solarray.bytess(
    //             abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
    //             abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
    //         )
    //     });
    // }

    // function test_multiswapRouterFacet_multiswap_partswapFromSeveralTokensIn_asd() external checkStorage {
    //     IMultiswapRouterFacet.MultiswapCalldata memory mData;

    //     mData.tokensIn = Solarray.bytes32s(
    //         Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
    //         Utils.encodeTokenAndAmount({ token: CAKE, amount: 1 }),
    //         Utils.encodeTokenAndAmount({ token: USDC, amount: 2 }),
    //         Utils.encodeTokenAndAmount({ token: USDT, amount: 2 }),
    //         Utils.encodeTokenAndAmount({ token: WBNB, amount: 2 }),
    //         Utils.encodeTokenAndAmount({ token: USDT, amount: 2 })
    //     );
    //     mData.pairs = Solarray.bytes32Arrays(
    //         Solarray.bytes32s(
    //             _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
    //             _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
    //             _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
    //         ),
    //         Solarray.bytes32s(_encodePercentageInPool(USDT_USDC_Bakery, 1e18)),
    //         Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_Biswap, 1e18)),
    //         Solarray.bytes32s(_encodePercentageInPool(WBNB_USDT_Biswap, 1e18)),
    //         Solarray.bytes32s(_encodePercentageInPool(BUSD_USDT_UniV3_3000, 1e18))
    //     );
    //     mData.tokensOut = Solarray.addresses(WBNB, CAKE, BUSD);

    //     IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
    //         tokens: Solarray.addresses(USDT, USDC),
    //         amounts: Solarray.uint256s(1000e18, 1000e18)
    //     });

    //     mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

    //     _resetPrank(user);

    //     IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });
    //     IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });

    //     entryPoint.multicall({
    //         tokenTransfers: tokenTransfers,
    //         data: Solarray.bytess(
    //             abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
    //             abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
    //         )
    //     });
    // }

    function test_multiswapRouterFacet_multiswap_swapToNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(WBNB_USDT_UniV3_500, 0.1e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_100, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Biswap, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.4e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_partswapToSeveralTokensOut() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.3e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_partswapFromSeveralTokensIn() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.5e18)
            ),
            Solarray.bytes32s(_encodePercentageInPool(BUSD_USDC_CakeV3_100, 1e18))
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, BUSD);

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(BUSD, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_partswapToSeveralTokensOut_shouldReturnAmountInIfOneOfPairsArrayIsEmpty(
    )
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.4e18), _encodePercentageInPool(WBNB_USDT_Cake, 0.6e18)
            ),
            new bytes32[](0)
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.3e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, owner, mData.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfOneOfTokensOutNotInPaths() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }));
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.2e18),
                _encodePercentageInPool(USDT_USDC_Bakery, 0.2e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.3e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.3e18)
            )
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE);
        mData.minAmountsOut = Solarray.uint256s(0, 0);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapToERC20TokenAndNative() external checkStorage {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.tokensIn = Solarray.bytes32s(
            Utils.encodeTokenAndAmount({ token: USDT, amount: 1 }),
            Utils.encodeTokenAndAmount({ token: USDC, amount: 2 })
        );
        mData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(
                _encodePercentageInPool(USDT_CAKE_Cake, 0.4e18),
                _encodePercentageInPool(WBNB_USDT_Cake, 0.4e18),
                _encodePercentageInPool(WBNB_USDT_CakeV3_500, 0.2e18)
            ),
            Solarray.bytes32s(_encodePercentageInPool(BUSD_USDC_Cake, 1e18))
        );
        mData.tokensOut = Solarray.addresses(WBNB, CAKE, BUSD);

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        mData.minAmountsOut = quoter.multiswap({ tokenTransfers: tokenTransfers, data: mData });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(CAKE, user, mData.minAmountsOut[1]);
        _expectERC20TransferCall(BUSD, user, mData.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, BUSD))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }
}
