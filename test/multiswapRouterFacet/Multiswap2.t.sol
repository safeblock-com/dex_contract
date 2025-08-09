// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract Multiswap2Test is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDC, to: user, give: 1000e18 });
        deal({ token: USDT, to: user, give: 1000e18 });
    }

    // =========================
    // multiswap2
    // =========================

    function test_multiswapRouterFacet_multiswap2_shouldRevertWithoutMulticall() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert();
        MultiswapRouterFacet(address(entryPoint)).multiswap2({ data: m2Data });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfPairsArrayIsEmpty() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfPairsArrayLengthIsNotEqualToPercentagesArrayLength()
        external
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake));
        m2Data.tokensOut = Solarray.addresses(USDC);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfTokensOutArrayIsEmpty() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = new address[](0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfTokensOutArrayLengthIsNotEqualToMinAmountsOutArrayLength(
    )
        external
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);
        m2Data.minAmountsOut = new uint256[](0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });

        m2Data.tokensOut = Solarray.addresses(WBNB, USDC);
        m2Data.minAmountsOut = Solarray.uint256s(0, 0, 0);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfTokensOutArrayNotUnique() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC, USDC);
        m2Data.minAmountsOut = Solarray.uint256s(0, 0);

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });

        m2Data.tokensOut = Solarray.addresses(WBNB, USDC, WBNB);
        m2Data.minAmountsOut = Solarray.uint256s(0, 0, 0);

        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });

        m2Data.tokensOut = Solarray.addresses(USDC, WBNB, WBNB);
        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfAmountInIsZero() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1e18) });

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);
        m2Data.minAmountsOut = Solarray.uint256s(0);

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });

        m2Data.amountInPercentages = Solarray.uint256s(0.5e18, 0.5e18, 0);
        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfArrayNotEmptyAfterSwap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1e18, 1e18)
        });

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);
        m2Data.minAmountsOut = Solarray.uint256s(0);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_failedV3Swap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDC;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_UniV3_500));
        m2Data.tokensOut = Solarray.addresses(CAKE);
        m2Data.minAmountsOut = Solarray.uint256s(0);

        deal({ token: USDC, to: user, give: 100e18 });

        assertEq(quoter.multiswap2({ data: m2Data })[0], 0);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.MultiswapRouterFacet_FailedV3Swap.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_failedV2Swap() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(0x0000000000000000000009c016b9a82891338f9bA80E2D6970FddA79D1eb0daE)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);
        m2Data.minAmountsOut = Solarray.uint256s(0);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.MultiswapRouterFacet_FailedV2Swap.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV2Pairs() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(USDC);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(USDC, user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV3Pairs() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        _expectERC20TransferCall(WBNB, user, m2Data.minAmountsOut[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfTokenNotTransferredFromContract() external {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)))
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfAmountOutLtMinAmountOut() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        m2Data.minAmountsOut = Solarray.uint256s(quoter.multiswap2({ data: m2Data })[0] + 1);

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(
            abi.encodeWithSelector(
                IErrors.ValueLowerThanExpected.selector, m2Data.minAmountsOut[0] - 1, m2Data.minAmountsOut[0]
            )
        );
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_partswapNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        deal({ to: user, give: 10e18 });

        m2Data.fullAmount = 10e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.1e18, 0.2e18, 0.3e18, 0.3e18, 0.1e18);
        m2Data.tokenIn = WBNB;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_ETH_Cake),
            Solarray.bytes32s(WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_3000),
            Solarray.bytes32s(WBNB_ETH_Bakery)
        );
        m2Data.tokensOut = Solarray.addresses(ETH);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(address(0)), amounts: Solarray.uint256s(10e18) });

        _resetPrank(user);

        _expectERC20TransferCall(ETH, user, m2Data.minAmountsOut[0]);
        entryPoint.multicall{ value: 10e18 }({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_swapToNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.1e18, 0.2e18, 0.3e18, 0.4e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_100),
            Solarray.bytes32s(WBNB_USDT_Biswap),
            Solarray.bytes32s(WBNB_USDT_Cake)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 100e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOut() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.2e18, 0.3e18, 0.3e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_Bakery),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, m2Data.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, m2Data.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, m2Data.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOut_shouldReturnAmountInIfOneOfPairsArrayIsEmpty(
    )
        external
        checkStorage
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.3e18, 0.5e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake), Solarray.bytes32s(WBNB_USDT_Cake), new bytes32[](0)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE, USDT);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, user, m2Data.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, m2Data.minAmountsOut[1]);
        _expectERC20TransferCall(USDT, user, m2Data.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkStorage
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.2e18, 0.3e18, 0.3e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_Bakery),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE, USDC);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(WBNB, owner, m2Data.minAmountsOut[0]);
        _expectERC20TransferCall(CAKE, user, m2Data.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, m2Data.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapToERC20TokenAndNative() external checkStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 1000e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.2e18, 0.2e18, 0.3e18, 0.3e18);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake, BUSD_CAKE_Biswap),
            Solarray.bytes32s(USDT_USDC_Bakery),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(WBNB, BUSD, USDC);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), 1000e18);
        _expectERC20TransferCall(BUSD, user, m2Data.minAmountsOut[1]);
        _expectERC20TransferCall(USDC, user, m2Data.minAmountsOut[2]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(BUSD, USDC))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }
}
