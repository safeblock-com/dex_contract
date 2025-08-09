// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract MultiswapReverseTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();
    }

    // одинаковые токены, одинаковые пары

    // =========================
    // multiswapReverse
    // =========================

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertWithoutMulticall() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        vm.expectRevert();
        MultiswapRouterFacet(address(entryPoint)).multiswapReverse({ data: mRData });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensOutLengthIsZero() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = new address[](0);

        _resetPrank(user);

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensOutLengthIsNotEqualPairsLength() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake));
        mRData.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });

        mRData.pairs = new bytes32[][](0);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensOutArrayLengthIsNotEqualAmountsOutLength()
        external
    {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut =
            Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC), _getReserveOut(USDT_USDC_Cake, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });

        mRData.amountsOut = new uint256[](0);

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensInArrayIsNotUnique() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT, USDT);
        mRData.amountsOut =
            Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC), _getReserveOut(USDT_USDC_Cake, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake));
        mRData.tokensOut = Solarray.addresses(USDC, USDC);

        _resetPrank(user);

        vm.expectRevert(IErrors.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensInArrayIsEmpty() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = new address[](0);
        mRData.amountsOut = Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensInArrayIsNotEqualToActualTokensArrayLength()
        external
    {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(_getReserveOut(USDT_USDC_Biswap, USDC));

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = Solarray.addresses(USDC);

        _resetPrank(user);

        // empty tokenTransfers
        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({ tokens: new address[](0), amounts: new uint256[](0) }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });

        deal({ token: USDT, to: user, give: 1e18 });
        deal({ token: USDC, to: user, give: 1e18 });

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1e18 });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: 1e18 });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: IEntryPoint.TokenTransfers({
                tokens: Solarray.addresses(USDT, USDC),
                amounts: Solarray.uint256s(1e18, 1e18)
            }),
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfOneOfAmountsOutIsZero() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(10e18);

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = Solarray.addresses(USDC);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        mRData.amountsOut[0] = 0;

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });

        mRData.amountsOut = Solarray.uint256s(10e18, 10e18);

        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDT_USDC_Cake), Solarray.bytes32s(USDT_USDC_Biswap));
        mRData.tokensOut = Solarray.addresses(USDC, USDC);

        (tokensIn, amountsIn) = quoter.multiswapReverse({ data: mRData });

        tokenTransfers = IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        mRData.amountsOut[1] = 0;

        vm.expectRevert(abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, 0, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_failedV3Swap() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDC);
        mRData.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(USDC_CAKE_UniV3_500));
        mRData.tokensOut = Solarray.addresses(CAKE);
        mRData.amountsOut = Solarray.uint256s(1e18);

        deal({ token: USDC, to: user, give: 100e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);

        IERC20(USDC).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.MultiswapRouterFacet_FailedV3Swap.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mRData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_failedV2Swap() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(0.1e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(0x0000000000000000000009c016b9a82891338f9bA80E2D6970FddA79D1eb0daE)
        );
        mRData.tokensOut = Solarray.addresses(WBNB);

        deal({ token: USDT, to: user, give: 100e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(100e18) });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IErrors.MultiswapRouterFacet_FailedV2Swap.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mRData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokensAndAmountsArrayNotEmpty()
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake)
        );
        mRData.tokensOut = Solarray.addresses(USDC, USDC);

        (, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDC), amounts: amountsIn });

        deal({ token: USDC, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDC).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(USDC)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldSwapThroughAllUniswapV2Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Cake)
        );
        mRData.tokensOut = Solarray.addresses(USDC, USDC);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(USDC, user, 3e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(USDC)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldSwapThroughAllUniswapV3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        mRData.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(WBNB, user, 6e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldSwapThroughAllUniswapV3PairsAndReturnsRemainderToUser()
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        mRData.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        amountsIn[0] += 1e18;

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(USDT, user, 1e18);
        _expectERC20TransferCall(WBNB, user, 6e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfTokenNotTransferredFromContract() external {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        mRData.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        vm.expectRevert(IErrors.ValuesNotEqual.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldRevertIfAmountInGtMaxAmountOut() external checkStorage {
        deal({ token: USDT, to: address(entryPoint), give: 1e18 });

        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        mRData.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        amountsIn[0] -= 1e18;

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        vm.expectRevert(
            abi.encodeWithSelector(IErrors.ValueLowerThanExpected.selector, amountsIn[0], amountsIn[0] + 1e18)
        );
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)))
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_partswapNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(WBNB);
        mRData.amountsOut = Solarray.uint256s(0.1e18, 0.05e18, 0.05e18, 0.05e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_ETH_Cake),
            Solarray.bytes32s(WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_3000)
        );
        mRData.tokensOut = Solarray.addresses(ETH, ETH, ETH, ETH);

        (, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(address(0)), amounts: amountsIn });

        deal({ to: user, give: amountsIn[0] });

        _resetPrank(user);

        _expectERC20TransferCall(ETH, user, 0.25e18);
        entryPoint.multicall{ value: amountsIn[0] }({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(ITransferFacet.transferToken, (user, Solarray.addresses(ETH)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_swapToNativeThroughV2V3Pairs() external checkStorage {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(1e18, 2e18, 3e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(ETH_USDT_UniV3_500, WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_Cake)
        );
        mRData.tokensOut = Solarray.addresses(WBNB, WBNB, WBNB);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_partswapToSeveralTokensOut_shouldReturnAmountOutIfOneOfPairsArrayIsEmpty(
    )
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 0.05e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_UniV3_100),
            Solarray.bytes32s(WBNB_USDT_Cake),
            new bytes32[](0)
        );
        mRData.tokensOut = Solarray.addresses(CAKE, USDC, WBNB, USDT);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(CAKE, user, 10e18);
        _expectERC20TransferCall(USDC, user, 1e18);
        _expectERC20TransferCall(WBNB, user, 0.1e18);
        _expectERC20TransferCall(USDT, user, 0.05e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, mRData.tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkStorage
    {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT);
        mRData.amountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 0.05e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(USDT_USDC_UniV3_100),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        mRData.tokensOut = Solarray.addresses(CAKE, USDC, WBNB, WBNB);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferCall(CAKE, user, 10e18);
        _expectERC20TransferCall(USDC, user, 1e18);
        _expectERC20TransferCall(WBNB, owner, 0.15e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswapReverse_shouldSwapToERC20TokenAndNative() external checkStorage {
        IMultiswapRouterFacet.MultiswapReverseCalldata memory mRData;

        mRData.tokensIn = Solarray.addresses(USDT, USDC);
        mRData.amountsOut = Solarray.uint256s(10e18, 1e18, 0.1e18, 1e18);
        mRData.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_CAKE_Cake),
            Solarray.bytes32s(WBNB_USDT_Cake),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500),
            Solarray.bytes32s(BUSD_USDC_Cake)
        );
        mRData.tokensOut = Solarray.addresses(CAKE, WBNB, WBNB, BUSD);

        (address[] memory tokensIn, uint256[] memory amountsIn) = quoter.multiswapReverse({ data: mRData });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: tokensIn, amounts: amountsIn });

        deal({ token: USDT, to: user, give: amountsIn[0] });
        deal({ token: USDC, to: user, give: amountsIn[1] });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: amountsIn[0] });
        IERC20(USDC).approve({ spender: address(entryPoint), amount: amountsIn[1] });

        _expectERC20TransferFromCall(USDT, user, address(entryPoint), amountsIn[0]);
        _expectERC20TransferFromCall(USDC, user, address(entryPoint), amountsIn[1]);
        _expectERC20TransferCall(CAKE, user, 10e18);
        _expectERC20TransferCall(BUSD, user, 1e18);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(MultiswapRouterFacet.multiswapReverse, (mRData)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, BUSD))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });
    }

    // =================================================
    // helpers
    // =================================================

    function _getReserveOut(bytes32 pair, address tokenOut) private view returns (uint256) {
        IUniswapPool _pair = IUniswapPool(address(uint160(uint256(pair))));

        (uint256 reserve0, uint256 reserve1,) = _pair.getReserves();
        address token0 = _pair.token0();

        if (token0 == tokenOut) {
            return (reserve0 > 0 ? (reserve0 >> 1) : 0);
        } else {
            return (reserve1 > 0 ? (reserve1 >> 1) : 0);
        }
    }
}
