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
    IRouter,
    console
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

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfMultiswap2DataIsInvalid() external checkTokenStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        _resetPrank(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // amountIn array length and pairs length are not equal
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.tokenIn = USDT;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000));
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // fullAmountCheck
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidMultiswap2Calldata.selector);
        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1.001e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        m2Data.tokenIn = USDT;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(BUSD_USDT_UniV3_3000));

        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data))) });
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV2Pairs() external checkTokenStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(USDT_USDC_Biswap), Solarray.bytes32s(USDT_USDC_Bakery), Solarray.bytes32s(USDT_USDC_Cake)
        );
        m2Data.tokenOut = USDC;

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(USDC).balanceOf({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_multiswap2_shouldSwapThroughAllUniswapV3Pairs() external checkTokenStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokenOut = WBNB;

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_multiswap2_shouldRevertIfAmountOutLtMinAmountOut() external checkTokenStorage {
        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.tokenIn = USDT;
        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(0.25e18, 0.25e18, 0.5e18);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_3000),
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_500)
        );
        m2Data.tokenOut = WBNB;

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountOut = quoterAmountOut + 1;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    // =========================
    // partswap with native
    // =========================

    function test_multiswapRouterFacet_multiswap2_partswapNativeThroughV2V3Pairs() external checkTokenStorage {
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
        m2Data.tokenOut = ETH;

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);

        entryPoint.multicall{ value: 10e18 }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(ETH).balanceOf({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_multiswap2_swapToNativeThroughV2V3Pairs() external checkTokenStorage {
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
        m2Data.tokenOut = WBNB;

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);
    }

    // =========================
    // multiswap2 with fee
    // =========================

    function test_multiswapRouterFacet_multiswap2_shouldCalculateFee() external checkTokenStorage {
        _resetPrank(owner);
        quoter.setFeeContract({ newFeeContract: address(feeContract) });
        // 0.03%
        feeContract.setProtocolFee({ newProtocolFee: 300 });

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
        m2Data.tokenOut = WBNB;

        uint256 quoterAmountOut = quoter.multiswap2({ data: m2Data });

        m2Data.minAmountOut = quoterAmountOut;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        _expectERC20TransferCall(WBNB, address(feeContract), quoterAmountOut * 300 / (1e6 - 300));
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);
        assertEq(feeContract.profit({ owner: address(feeContract), token: WBNB }), quoterAmountOut * 300 / (1e6 - 300));
    }

    // =========================
    // no transfer revert
    // =========================

    function test_multiswapRouterFacet_multiswap2_noTransferRevert() external checkTokenStorage {
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

        _resetPrank(user);
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
                abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    struct Amounts {
        uint256 amount1;
        uint256 amount2;
        uint256 amount3;
        uint256 amount4;
    }

    function test_multiswapRouterFacet_multiswap2_test() external checkTokenStorage {
        Amounts memory amounts;

        IMultiswapRouterFacet.Multiswap2Calldata memory m2Data;

        m2Data.fullAmount = 100e18;
        m2Data.amountInPercentages = Solarray.uint256s(1e18);
        m2Data.tokenIn = USDT;
        m2Data.tokenOut = WBNB;

        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(WBNB_USDT_UniV3_500));

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });
        uint256 quoterAmountIn = m2Data.fullAmount;
        amounts.amount1 = m2Data.fullAmount;

        console.log("quoter1", quoter.multiswap2({ data: m2Data }));

        m2Data.fullAmount = 100e18;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(WBNB_USDT_CakeV3_100));

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });
        quoterAmountIn += m2Data.fullAmount;
        amounts.amount2 = m2Data.fullAmount;

        console.log("quoter2", quoter.multiswap2({ data: m2Data }));

        m2Data.fullAmount = 100e18;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(WBNB_USDT_Biswap));

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });
        quoterAmountIn += m2Data.fullAmount;
        amounts.amount3 = m2Data.fullAmount;

        console.log("quoter3", quoter.multiswap2({ data: m2Data }));

        m2Data.fullAmount = 100e18;
        m2Data.pairs = Solarray.bytes32Arrays(Solarray.bytes32s(WBNB_USDT_Cake));

        m2Data.fullAmount = quoter.multiswap2Reverse({ data: m2Data });
        quoterAmountIn += m2Data.fullAmount;
        amounts.amount4 = m2Data.fullAmount;

        console.log("quoter4", quoter.multiswap2({ data: m2Data }));

        console.log("quoterAmountIn", quoterAmountIn);

        amounts.amount1 = amounts.amount1 * 1e18 / quoterAmountIn;
        amounts.amount2 = amounts.amount2 * 1e18 / quoterAmountIn;
        amounts.amount3 = amounts.amount3 * 1e18 / quoterAmountIn;
        amounts.amount4 = 1e18 - amounts.amount1 - amounts.amount2 - amounts.amount3;

        m2Data.amountInPercentages =
            Solarray.uint256s(amounts.amount1, amounts.amount2, amounts.amount3, amounts.amount4);
        m2Data.pairs = Solarray.bytes32Arrays(
            Solarray.bytes32s(WBNB_USDT_UniV3_500),
            Solarray.bytes32s(WBNB_USDT_CakeV3_100),
            Solarray.bytes32s(WBNB_USDT_Biswap),
            Solarray.bytes32s(WBNB_USDT_Cake)
        );

        m2Data.fullAmount = quoterAmountIn;

        console.log("fullAmountOut", quoter.multiswap2({ data: m2Data }));

        // m2Data.minAmountOut = quoterAmountIn * 1.02e18 / 1e18;

        // _resetPrank(user);

        // IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        // uint256 userBalanceBefore = user.balance;

        // entryPoint.multicall({
        // data: Solarray.bytess(
        // abi.encodeCall(IMultiswapRouterFacet.multiswap2, (m2Data)),
        // abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
        // )
        // });

        // assertEq(user.balance - userBalanceBefore, quoterAmountOut);
    }
}
