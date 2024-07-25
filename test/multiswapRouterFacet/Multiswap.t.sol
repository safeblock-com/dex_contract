// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "solarray/Solarray.sol";
import { DeployEngine } from "../../script/DeployEngine.sol";
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
    // multiswap
    // ==========================

    function test_multiswapRouterFacet_multiswap_shouldRevertIfMultiswapDataIsInvalid() external {
        IMultiswapRouterFacet.MultiswapCalldata memory mData;

        startHoax(user);

        // pairs array is empty
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPairsArray.selector);
        IMultiswapRouterFacet(address(router)).multiswap(mData);

        // amountIn is 0
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        IMultiswapRouterFacet(address(router)).multiswap(mData);

        // tokenIn is address(0) (native) and msg.value < amountIn
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidAmountIn.selector);
        mData.amountIn = 1;
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000);
        IMultiswapRouterFacet(address(router)).multiswap(mData);

        // not approved
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(WBNB_CAKE_CakeV3_500, BUSD_USDT_UniV3_3000);
        IMultiswapRouterFacet(address(router)).multiswap(mData);

        IERC20(USDT).approve(address(router), 100e18);

        // tokenIn is not in sent pair
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(WBNB_CAKE_CakeV3_500, BUSD_USDT_UniV3_3000);
        IMultiswapRouterFacet(address(router)).multiswap(mData);

        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidTokenIn.selector);
        mData.tokenIn = USDT;
        mData.amountIn = 100e18;
        mData.pairs = Solarray.bytes32s(BUSD_USDT_UniV3_3000, WBNB_CAKE_CakeV3_500);
        IMultiswapRouterFacet(address(router)).multiswap(mData);

        vm.stopPrank();
    }
}
