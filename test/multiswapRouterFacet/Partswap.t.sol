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
    ITransferFacet
} from "../BaseTest.t.sol";

import "../Helpers.t.sol";

contract PartswapTest is BaseTest {
    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

        _createUsers();

        _resetPrank(owner);

        deployForTest();

        deal({ token: USDT, to: user, give: 1000e18 });
    }

    // =========================
    // partswap
    // =========================

    function test_multiswapRouterFacet_partswap_shouldRevertIfPartswapDataIsInvalid() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        _resetPrank(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))) });

        // amountIn array length and pairs length are not equal
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))) });

        // fullAmountCheck
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(100.1e18);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))) });

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        pData.tokenIn = USDT;
        pData.amountsIn = Solarray.uint256s(100e18);
        pData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))) });
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV2Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 50e18);
        pData.pairs = Solarray.bytes32s(USDT_USDC_Biswap, USDT_USDC_Bakery, USDT_USDC_Cake);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = USDC;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(USDC).balanceOf({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV2PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(USDT_USDC_Biswap, USDT_USDC_Bakery, USDT_USDC_Cake);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = USDC;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(USDC).balanceOf({ account: user }), quoterAmountOut);
        assertEq(IERC20(USDT).balanceOf({ account: user }), 925e18);
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV3Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 50e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV3PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(WBNB).balanceOf({ account: user }), quoterAmountOut);
        assertEq(IERC20(USDT).balanceOf({ account: user }), 925e18);
    }

    function test_multiswapRouterFacet_partswap_shouldRevertIfAmountOutLtMinAmountOut() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut + 1;
        pData.tokenOut = WBNB;

        _resetPrank(user);
        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }

    // =========================
    // partswap with native
    // =========================

    function test_multiswapRouterFacet_partswap_partswapNativeThroughV2V3Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        deal({ to: user, give: 10e18 });

        pData.fullAmount = 10e18;
        pData.amountsIn = Solarray.uint256s(1e18, 2e18, 3e18, 3e18, 1e18);
        pData.tokenIn = address(0);
        pData.pairs = Solarray.bytes32s(
            WBNB_ETH_Bakery, WBNB_ETH_UniV3_3000, WBNB_ETH_UniV3_500, WBNB_ETH_CakeV3_500, WBNB_ETH_Cake
        );

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = ETH;

        _resetPrank(user);

        entryPoint.multicall{ value: 10e18 }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(ETH).balanceOf({ account: user }), quoterAmountOut);
    }

    function test_multiswapRouterFacet_partswap_partswapNativeThroughV2V3PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        deal({ to: user, give: 10e18 });

        pData.fullAmount = 10e18;
        pData.amountsIn = Solarray.uint256s(1e18, 2e18, 3e18, 2e18, 1e18);
        pData.tokenIn = address(0);
        pData.pairs = Solarray.bytes32s(
            WBNB_ETH_Bakery, WBNB_ETH_UniV3_3000, WBNB_ETH_UniV3_500, WBNB_ETH_CakeV3_500, WBNB_ETH_Cake
        );

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = ETH;

        _resetPrank(user);

        entryPoint.multicall{ value: 10e18 }({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });

        assertEq(IERC20(ETH).balanceOf({ account: user }), quoterAmountOut);
        assertEq(IERC20(WBNB).balanceOf({ account: user }), 1e18);
    }

    function test_multiswapRouterFacet_partswap_swapToNativeThroughV2V3Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(10e18, 20e18, 30e18, 40e18);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, WBNB_USDT_CakeV3_100, WBNB_USDT_UniV3_500);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);
    }

    function test_multiswapRouterFacet_partswap_swapToNativeThroughV2V3PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(10e18, 20e18, 30e18, 30e18);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, WBNB_USDT_CakeV3_100, WBNB_USDT_UniV3_500);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);
        assertEq(IERC20(USDT).balanceOf({ account: user }), 910e18);
    }

    // =========================
    // partswap with fee
    // =========================

    function test_multiswapRouterFacet_partswap_shouldCalculateFee() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(10e18, 20e18, 30e18, 40e18);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, WBNB_USDT_CakeV3_100, WBNB_USDT_UniV3_500);

        uint256 quoterAmountOut = quoter.partswap({ data: pData });

        pData.minAmountOut = quoterAmountOut;
        pData.tokenOut = WBNB;

        _resetPrank(owner);
        // 0.03%
        feeContract.setProtocolFee({ newProtocolFee: 300 });

        _resetPrank(user);

        IERC20(USDT).approve({ spender: address(entryPoint), amount: 100e18 });

        uint256 userBalanceBefore = user.balance;

        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user))
            )
        });

        uint256 fee = quoterAmountOut * 300 / 1e6;

        assertApproxEqAbs(user.balance - userBalanceBefore, quoterAmountOut - fee, 0.0001e18);
        assertEq(feeContract.profit({ owner: address(feeContract), token: WBNB }), fee);
    }

    // =========================
    // no transfer revert
    // =========================

    function test_multiswapRouterFacet_partswap_noTransferRevert() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        deal({ token: USDT, to: address(entryPoint), give: 100e18 });

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        _resetPrank(user);
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)), abi.encodeCall(TransferFacet.transferToken, (user))
            )
        });
    }
}
