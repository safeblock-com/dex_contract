// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "solarray/Solarray.sol";

import { FeeContract, IFeeContract } from "../src/FeeContract.sol";

import { EntryPoint } from "../src/EntryPoint.sol";
import { DeployEngine } from "../script/DeployEngine.sol";
import { MultiswapRouterFacet, IMultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";

import { IOwnable } from "../src/external/IOwnable.sol";
import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import "./Helpers.t.sol";

contract PartswapTest is Test {
    MultiswapRouterFacet router;
    FeeContract feeContract;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address referral = makeAddr("referral");

    function setUp() external {
        vm.createSelectFork(vm.envString("BNB_RPC_URL"));

        deal(WBNB, user, 500e18);

        startHoax(owner);
        feeContract = new FeeContract(owner);

        feeContract.changeProtocolFee(300);
        feeContract.changeReferralFee(IFeeContract.ReferralFee({ protocolPart: 200, referralPart: 50 }));

        address routerImplementation = address(new MultiswapRouterFacet(WBNB));
        router = MultiswapRouterFacet(address(new Proxy(owner)));

        feeContract.changeRouter(address(router));

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = IMultiswapRouterFacet.multiswap.selector;
        selectors[1] = IMultiswapRouterFacet.partswap.selector;
        selectors[2] = IMultiswapRouterFacet.wrappedNative.selector;
        selectors[3] = IMultiswapRouterFacet.feeContract.selector;
        selectors[4] = IMultiswapRouterFacet.setFeeContract.selector;
        address[] memory facets = Solarray.addresses(
            routerImplementation, routerImplementation, routerImplementation, routerImplementation, routerImplementation
        );

        bytes[] memory initData =
            Solarray.bytess(abi.encodeCall(IMultiswapRouterFacet.setFeeContract, address(feeContract)));

        InitialImplementation(address(router)).upgradeTo(
            address(new EntryPoint(DeployEngine.getBytesArray(selectors, facets))),
            abi.encodeCall(EntryPoint.initialize, (owner, initData))
        );
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV3() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV2() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV3_referral() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV2_referral() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV3() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 1_000_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = WBNB_BUSD_UniV3_500;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV2() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 1_000_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV2AndV3_referral() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 1_000_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_CakeV3_500;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaThreePairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 1_500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](3);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_CakeV3_10000;
        data.pairs[2] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaFourPairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 2_000_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.amountsIn[3] = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_shouldRevertWithInvalidCalldata() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 2_000_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 600_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.amountsIn[3] = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        router.partswap(data, user);

        data.fullAmount = 2_000_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](3);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        router.partswap(data, user);

        vm.stopPrank();
    }

    // native swaps

    function test_multiswapRouter_partswapWithNative_swapViaOnePairV3() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 500_000_000;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        hoax(user);
        router.partswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaOnePairV2() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 500_000_000;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        hoax(user);
        router.partswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaOnePairV3_referral() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 500_000_000;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        hoax(user);
        router.partswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaOnePairV2_referral() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 500_000_000;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.referralAddress = referral;

        hoax(user);
        router.partswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaTwoPairsV3() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 1_000_000_000;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = WBNB_BUSD_UniV3_500;

        hoax(user);
        router.partswap{ value: 1_000_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaTwoPairsV2() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 1_000_000_000;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;

        hoax(user);
        router.partswap{ value: 1_000_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaTwoPairsV2AndV3_referral() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 1_000_000_000;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_CakeV3_500;
        data.referralAddress = referral;

        hoax(user);
        router.partswap{ value: 1_000_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaThreePairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 1_500_000_000;
        data.amountsIn = new uint256[](3);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_CakeV3_10000;
        data.pairs[2] = WBNB_BUSD_Bakery;

        hoax(user);
        router.partswap{ value: 1_500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_swapViaFourPairs() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.tokenOut = BUSD;
        data.fullAmount = 2_000_000_000;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.amountsIn[3] = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        hoax(user);
        router.partswap{ value: 2_000_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_partswapWithNative_shouldRevertWithInvalidCalldata() external {
        IMultiswapRouterFacet.PartswapCalldata memory data;
        data.fullAmount = 2_000_000_000;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 600_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.amountsIn[3] = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        hoax(user);
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        router.partswap{ value: 2_000_000_000 }(data, user);

        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](3);
        data.amountsIn[0] = 500_000_000;
        data.amountsIn[1] = 500_000_000;
        data.amountsIn[2] = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        hoax(user);
        vm.expectRevert(IMultiswapRouterFacet.MultiswapRouterFacet_InvalidPartswapCalldata.selector);
        router.partswap{ value: 2_000_000_000 }(data, user);
    }
}
