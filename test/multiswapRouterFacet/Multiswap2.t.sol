// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BaseTest,
    IERC20,
    Solarray,
    IOwnable,
    TransferHelper,
    MultiswapRouterFacet,
    IMultiswapRouterFacet,
    TransferFacet,
    ITransferFacet,
    console,
    EfficientSwapAmount,
    IUniswapPool,
    HelperV3Lib,
    TransientStorageFacetLibrary
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract Multiswap2Test is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });
    }

    // =========================
    // multiswap2
    // =========================

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfMultiswap2DataIsInvalid()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 100e18;
        m2Data.tokenIn = USDT;

        _resetPrank(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // amountInPercentages array length and pairs length are not equal
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.amountInPercentages = Solarray.uint256s(0.45e18, 0.55e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000));
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // tokensOut length check
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.tokensOut = Solarray.addresses(USDC);
        m2Data.minAmountsOut = Solarray.uint256s(1e18, 1e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // fullAmountCheck
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.minAmountsOut = Solarray.uint256s(1e18);
        m2Data.pairs =
            Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000), Solarray.bytes32s(BUSD_USDT_UniV3_3000));
        m2Data.amountInPercentages = Solarray.uint256s(0.45e18, 0.56e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        m2Data.amountInPercentages = Solarray.uint256s(0.45e18, 0.55e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV2Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, USDC))
    {
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

        address[] memory tokensOut = Solarray.addresses(USDC);

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });

        assertEq(IERC20(USDC).balanceOf({ account: user }), quoterAmountOut[0]);
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV3Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
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

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(WBNB);

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), quoterAmountOut[0]);
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

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] * 0.98e18 / 1e18);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(USDC);

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfAmountOutLtMinAmountOut()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
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

        uint256[] memory quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountsOut = Solarray.uint256s(quoterAmountOut[0] + 1);

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        address[] memory tokensOut = Solarray.addresses(WBNB);

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, tokensOut))
            )
        });
    }

    // =========================
    // partswap with native
    // =========================

    function test_multiswapRouterFacet_multiswap2_partswapNativeThroughV2V3Pairs()
        external
        checkTokenStorage(Solarray.addresses(WBNB, ETH))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        deal({ to: user, give: 10e18 });

        m2Data.fullAmount = 10e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.1e18, 0.2e18, 0.3e18, 0.3e18, 0.1e18);
        m2Data.tokenIn = address(0);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_ETH_Cake),
            Solarray.bytes32s(WBNB_ETH_CakeV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_500),
            Solarray.bytes32s(WBNB_ETH_UniV3_3000),
            Solarray.bytes32s(WBNB_ETH_Bakery)
        );
        m2Data.tokensOut = Solarray.addresses(ETH);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        entryPoint.multicall{ value: 10e18 }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(IERC20(ETH).balanceOf({ account: user }), m2Data.minAmountsOut[0]);
    }

    function test_multiswapRouterFacet_multiswap2_swapToNativeThroughV2V3Pairs()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, m2Data.minAmountsOut[0]);
    }

    // =========================
    // multiswap2 with fee
    // =========================

    function test_multiswapRouterFacet_multiswap2_shouldCalculateFee()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        _resetPrank(owner);
        quoter.setRouter({ router: address(entryPoint) });
        // 0.03%
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        _expectERC20TransferCall(USDT, address(feeContract), m2Data.fullAmount * 300 / 1e6);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(feeContract.profit({ token: USDT }), m2Data.fullAmount * 300 / 1e6);
    }

    // =========================
    // no transfer revert
    // =========================

    function test_multiswapRouterFacet_multiswap2_noTransferRevert()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB))
    {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        deal({ token: USDT, to: address(entryPoint), give: 100e18 });

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokensOut = Solarray.addresses(address(0));
        m2Data.minAmountsOut = Solarray.uint256s(0);

        _resetPrank(user);
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });
    }

    // =========================
    // partswap to several tokensOut
    // =========================

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOut()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, m2Data.tokensOut))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), m2Data.minAmountsOut[2]);
    }

    function test_multiswapRouterFacet_multiswap2_partswapToSeveralTokensOutAndTransferToSeveralRecipients()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.transferToken, (owner, Solarray.addresses(WBNB)))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: owner }), m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), m2Data.minAmountsOut[2]);
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfOneOfTokensOutNotTransferFromContract()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        vm.expectRevert(TransientStorageFacetLibrary.TokenNotTransferredFromContract.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfOneOfTokensOutNotInPaths()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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
        m2Data.tokensOut = Solarray.addresses(WBNB, CAKE);

        m2Data.minAmountsOut = quoter.multiswap2({ data: m2Data });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(WBNB, CAKE)))
            )
        });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapToERC20TokenAndNative()
        external
        checkTokenStorage(Solarray.addresses(USDT, WBNB, CAKE, USDC))
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

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 1000e18 });

        uint256 balanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user, Solarray.addresses(CAKE, USDC))),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - balanceBefore, m2Data.minAmountsOut[0]);
        assertEq(IERC20(CAKE).balanceOf({ account: user }), m2Data.minAmountsOut[1]);
        assertEq(IERC20(USDC).balanceOf({ account: user }), m2Data.minAmountsOut[2]);
    }
}
