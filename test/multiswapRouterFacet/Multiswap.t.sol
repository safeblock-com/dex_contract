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
import { IOwnable } from "../../src/external/IOwnable.sol";
import { TransferHelper } from "../../src/facets/libraries/TransferHelper.sol";

import { Quoter } from "../../src/lens/Quoter.sol";

import "../Helpers.t.sol";

contract MultiswapTest is Test {
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
    // constructor
    // =========================

    function test_multiswapRouterFacet_constructor_shouldInitializeInConstructor() external {
        MultiswapRouterFacet _multiswapRouterFacet = new MultiswapRouterFacet(WBNB);

        assertEq(_multiswapRouterFacet.wrappedNative(), WBNB);
    }

    // =========================
    // setFeeContract
    // =========================

    function test_multiswapRouterFacet_setFeeContract_shouldSetFeeContract() external {
        assertEq(IMultiswapRouterFacet(address(router)).feeContract(), address(0));

        hoax(user);
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, user));
        IMultiswapRouterFacet(address(router)).setFeeContract(user);

        hoax(owner);
        IMultiswapRouterFacet(address(router)).setFeeContract(owner);

        assertEq(IMultiswapRouterFacet(address(router)).feeContract(), owner);
    }

    // =========================
    // transferNative
    // =========================

    function test_transferFacet_transferNative_shouldTransferNativeFromContract() external {
        deal(address(router), 10e18);

        startHoax(user);

        uint256 balanceBefore = user.balance;

        router.multicall(Solarray.bytess(abi.encodeCall(TransferFacet.transferNative, (user, 5e18))));

        uint256 balanceAfter = user.balance;

        assertEq(balanceAfter - balanceBefore, 5e18);

        router.multicall(Solarray.bytess(abi.encodeCall(TransferFacet.transferNative, (user, 5e18))));

        assertEq(user.balance - balanceAfter, 5e18);

        vm.stopPrank();
    }

    // =========================
    // multiswap
    // =========================

    function test_multiswapRouterFacet_multiswap_shouldRevertIfMultiswapDataIsInvalid() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        startHoax(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))));

        // amountIn is 0
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))));

        // tokenIn is address(0) (native) and msg.value < amountIn
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        mData.amountIn = 1;
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))));

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(WBNB_CAKE_CakeV3_500, BUSD_USDT_UniV3_3000);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))));

        IERC20(USDT).approve(address(router), 100e18);

        // tokenIn is not in sent pair
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(WBNB_CAKE_CakeV3_500, BUSD_USDT_UniV3_3000);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))));

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000, WBNB_CAKE_CakeV3_500);
        router.multicall(Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData))));

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapThroughAllUniswapV2Pairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs =
            Solarray.bytes32s(USDT_USDC_Cake, USDC_CAKE_Cake, BUSD_CAKE_Biswap, BUSD_ETH_Biswap, WBNB_ETH_Bakery);

        uint256 quoterAmountOut = quoter.multiswap(mData);

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (WBNB, 0, user))
            )
        );

        assertEq(IERC20(WBNB).balanceOf(user), quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_multiswap_shouldSwapThroughAllUniswapV3Pairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(
            ETH_USDT_UniV3_500, WBNB_ETH_UniV3_500, WBNB_CAKE_UniV3_3000, WBNB_CAKE_CakeV3_500, WBNB_ETH_UniV3_3000
        );

        uint256 quoterAmountOut = quoter.multiswap(mData);

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (ETH, 0, user))
            )
        );

        assertEq(IERC20(ETH).balanceOf(user), quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_failedV3Swap() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        deal(USDC, user, 100e18);

        mData.amountIn = 100e18;
        mData.tokenIn = USDC;
        mData.pairs = Solarray.bytes32s(USDC_CAKE_UniV3_500);

        assertEq(quoter.multiswap(mData), 0);

        startHoax(user);
        IERC20(USDC).approve(address(router), 100e18);

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_FailedV3Swap.selector);
        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (WBNB, 0, user))
            )
        );

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_failedCallback() external {
        (, bytes memory data) = multiswapRouterFacet.call(abi.encodeWithSelector(TransferFacet.transferToken.selector));

        assertEq(bytes4(data), IMultiswapRouterFacet.MultiswapRouterFacet_SenderMustBeUniswapV3Pool.selector);
    }

    function test_multiswapRouterFacet_multiswap_shouldRevertIfAmountOutLtMinAmountOut() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs =
            Solarray.bytes32s(USDT_USDC_Cake, USDC_CAKE_Cake, BUSD_CAKE_Biswap, BUSD_ETH_Biswap, WBNB_ETH_Bakery);

        uint256 quoterAmountOut = quoter.multiswap(mData);

        mData.minAmountOut = quoterAmountOut + 1;

        startHoax(user);
        IERC20(USDT).approve(address(router), 100e18);

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountOut.selector);
        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (WBNB, 0, user))
            )
        );

        vm.stopPrank();
    }

    // =========================
    // multiswap with native
    // =========================

    function test_multiswapRouterFacet_multiswapNative() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 10e18;
        mData.tokenIn = address(0);
        mData.pairs =
            Solarray.bytes32s(WBNB_ETH_Bakery, BUSD_ETH_Biswap, BUSD_CAKE_Biswap, USDC_CAKE_Cake, USDT_USDC_Cake);

        uint256 quoterAmountOut = quoter.multiswap(mData);

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        startHoax(user);

        uint256 userBalanceBefore = IERC20(USDT).balanceOf(user);

        router.multicall{ value: 10e18 }(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.transferToken, (USDT, 0, user))
            )
        );

        assertEq(IERC20(USDT).balanceOf(user) - userBalanceBefore, quoterAmountOut);

        vm.stopPrank();
    }

    function test_multiswapRouterFacet_swapToNativeThroughV2V3Pairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        mData.amountIn = 100e18;
        mData.tokenIn = USDT;
        mData.pairs = Solarray.bytes32s(USDT_USDC_Cake, BUSD_USDC_CakeV3_100, BUSD_CAKE_Cake, WBNB_CAKE_CakeV3_100);

        uint256 quoterAmountOut = quoter.multiswap(mData);

        mData.minAmountOut = quoterAmountOut * 0.98e18 / 1e18;

        startHoax(user);

        IERC20(USDT).approve(address(router), 100e18);

        uint256 userBalanceBefore = user.balance;

        router.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000024,
            Solarray.bytess(
                abi.encodeCall(IMultiswapRouterFacet.multiswap, (mData)),
                abi.encodeCall(TransferFacet.unwrapNativeAndTransferTo, (user, 0))
            )
        );

        assertEq(user.balance - userBalanceBefore, quoterAmountOut);

        vm.stopPrank();
    }
}
