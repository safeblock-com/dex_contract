// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "solarray/Solarray.sol";
import { DeployEntryPoint } from "../../script/DeployContract.s.sol";

import { Proxy, InitialImplementation } from "../../src/proxy/Proxy.sol";

import { IEntryPoint } from "../../src/EntryPoint.sol";
import { MultiswapRouterFacet, IMultiswapRouterFacet } from "../../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet } from "../../src/facets/TransferFacet.sol";
import { TransferHelper } from "../../src/facets/libraries/TransferHelper.sol";

import { Quoter } from "../../src/lens/Quoter.sol";

import "../Helpers.t.sol";

contract PartswapTest is Test {
    IEntryPoint router;
    Quoter quoter;

    // TODO add later
    // FeeContract feeContract;

    address owner = makeAddr("owner");
    address user = makeAddr("user");

    address multiswapRouterFacet;
    address transferFacet;
    address entryPointImplementation;

    function setUp() external {
        vm.createSelectFork(vm.envString("BNB_RPC_URL"));

        deal(USDT, user, 1000e18);

        startHoax(owner);

        quoter = new Quoter(WBNB);

        multiswapRouterFacet = address(new MultiswapRouterFacet(WBNB));
        transferFacet = address(new TransferFacet(WBNB));

        entryPointImplementation = DeployEntryPoint.deployEntryPoint(transferFacet, multiswapRouterFacet);

        router = IEntryPoint(address(new Proxy(owner)));

        // TODO add later
        // bytes[] memory initData =
        // Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.setFeeContract, address(feeContract)));

        InitialImplementation(address(router)).upgradeTo(
            entryPointImplementation, abi.encodeCall(IEntryPoint.initialize, (owner, new bytes[](0)))
        );

        vm.stopPrank();
    }

    // =========================
    // partswap
    // =========================

    function test_multiswapRouterFacet_partswap_shouldRevertIfPartswapDataIsInvalid() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        startHoax(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))));

        // amountIn array length and pairs length are not equal
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))));

        // fullAmountCheck
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(100.1e18);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))));

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        pData.tokenIn = USDT;
        pData.amountsIn = Solarray.uint256s(100e18);
        pData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.partswap, (pData))));

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV2Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 50e18);
        pData.pairs = Solarray.bytes32s(USDT_USDC_Biswap, USDT_USDC_Bakery, USDT_USDC_Cake);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = USDC;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (USDC, 0, user))
            )
        );

        assertEq(IERC20(USDC).balanceOf(user), quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV2PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(USDT_USDC_Biswap, USDT_USDC_Bakery, USDT_USDC_Cake);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = USDC;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (USDC, 0, user))
            )
        );

        assertEq(IERC20(USDC).balanceOf(user), quoterAmountOut);
        assertEq(IERC20(USDT).balanceOf(user), 925e18);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV3Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 50e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (WBNB, 0, user))
            )
        );

        assertEq(IERC20(WBNB).balanceOf(user), quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_partswap_shouldSwapThroughAllUniswapV3PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (WBNB, 0, user))
            )
        );

        assertEq(IERC20(WBNB).balanceOf(user), quoterAmountOut);
        assertEq(IERC20(USDT).balanceOf(user), 925e18);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_partswap_shouldRevertIfAmountOutLtMinAmountOut() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.tokenIn = USDT;
        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(25e18, 25e18, 25e18);
        pData.pairs = Solarray.bytes32s(WBNB_USDT_CakeV3_500, WBNB_USDT_UniV3_500, WBNB_USDT_UniV3_3000);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut + 1;
        pData.tokenOut = WBNB;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (WBNB, 0, user))
            )
        );

        vm.stopPrank();
    }

    // =========================
    // partswap with native
    // =========================

    function test_multiswapRouterFacet_partswapNativeThroughV2V3Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 10e18;
        pData.amountsIn = Solarray.uint256s(1e18, 2e18, 3e18, 3e18, 1e18);
        pData.tokenIn = address(0);
        pData.pairs = Solarray.bytes32s(
            WBNB_ETH_Bakery, WBNB_ETH_UniV3_3000, WBNB_ETH_UniV3_500, WBNB_ETH_CakeV3_500, WBNB_ETH_Cake
        );

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = ETH;

        startHoax(user);

        router.multicall{ value: 10e18 }(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (ETH, 0, user))
            )
        );

        assertEq(IERC20(ETH).balanceOf(user), quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_partswapNativeThroughV2V3PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 10e18;
        pData.amountsIn = Solarray.uint256s(1e18, 2e18, 3e18, 2e18, 1e18);
        pData.tokenIn = address(0);
        pData.pairs = Solarray.bytes32s(
            WBNB_ETH_Bakery, WBNB_ETH_UniV3_3000, WBNB_ETH_UniV3_500, WBNB_ETH_CakeV3_500, WBNB_ETH_Cake
        );

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = ETH;

        startHoax(user);

        router.multicall{ value: 10e18 }(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.transferToken, (ETH, 0, user))
            )
        );

        assertEq(IERC20(ETH).balanceOf(user), quoterAmountOut);
        assertEq(IERC20(WBNB).balanceOf(user), 1e18);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_swapToNativeThroughV2V3Pairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(10e18, 20e18, 30e18, 40e18);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, WBNB_USDT_CakeV3_100, WBNB_USDT_UniV3_500);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        startHoax(user);

        IERC20(USDT).approve(address(router), 100e18);

        uint256 userBalanceBefore = user.balance;

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user, 0))
            )
        );

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_swapToNativeThroughV2V3PairsWithRemain() external {
        IMultiswapRouterFacet.PartswapCalldata memory pData;

        pData.fullAmount = 100e18;
        pData.amountsIn = Solarray.uint256s(10e18, 20e18, 30e18, 30e18);
        pData.tokenIn = USDT;
        pData.pairs = Solarray.bytes32s(WBNB_USDT_Cake, WBNB_USDT_Biswap, WBNB_USDT_CakeV3_100, WBNB_USDT_UniV3_500);

        uint256 quoterAmountOut = quoter.partswap(pData);

        pData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;
        pData.tokenOut = WBNB;

        startHoax(user);

        IERC20(USDT).approve(address(router), 100e18);

        uint256 userBalanceBefore = user.balance;

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.partswap, (pData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user, 0))
            )
        );

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);
        assertEq(IERC20(USDT).balanceOf(user), 910e18);

        vm.stopPrank();
    }
}
