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

contract MultiswapTest is Test {
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

    function test_multiswapRouter_multiswap_swapViaOnePairV3() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV3_referral() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV2() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV2_referral() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV3() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV2() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV2AndV3_referral() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
        assertGt(feeContract.profit(referral, CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaThreePairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), USDC), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaFourPairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;
        data.pairs[3] = USDC_CAKE_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
        vm.stopPrank();
    }

    event TransferHelperTransfer(address indexed token, address indexed from, address indexed to, uint256 value);

    function test_multiswapRouter_collectProtocolFees_shouldWithdrawPartOfFees() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        uint256 fees = feeContract.profit(address(feeContract), BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, address(1)));
        feeContract.collectProtocolFees(BUSD, address(1), fees >> 1);

        vm.prank(owner);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(feeContract), user, fees >> 1);
        feeContract.collectProtocolFees(BUSD, user, fees >> 1);

        assertApproxEqAbs(feeContract.profit(address(feeContract), BUSD), fees >> 1, 2);
    }

    function test_multiswapRouter_collectProtocolFees_shouldWithdrawAllFees() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        uint256 fees = feeContract.profit(address(feeContract), BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, address(1)));
        feeContract.collectProtocolFees(BUSD, address(1));

        vm.prank(owner);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(feeContract), user, fees);
        feeContract.collectProtocolFees(BUSD, user);

        assertEq(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_collectReferralFees_shouldWithdrawPartOfFees() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        uint256 fees = feeContract.profit(referral, BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        // did nothing
        vm.prank(address(1));
        feeContract.collectReferralFees(BUSD, address(1), fees >> 1);

        vm.prank(referral);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(feeContract), user, fees >> 1);
        feeContract.collectReferralFees(BUSD, user, fees >> 1);

        assertApproxEqAbs(feeContract.profit(referral, BUSD), fees >> 1, 2);
    }

    function test_multiswapRouter_collectReferralFees_shouldWithdrawAllFees() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data, user);

        uint256 fees = feeContract.profit(referral, BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        // did nothing
        vm.prank(address(1));
        feeContract.collectReferralFees(BUSD, address(1));

        vm.prank(referral);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(feeContract), user, fees);
        feeContract.collectReferralFees(BUSD, user);

        assertEq(feeContract.profit(referral, BUSD), 0);
    }

    // native swaps

    function test_multiswapRouter_multiswapWithNative_swapViaOnePairV3() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaOnePairV3_referral() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaOnePairV2() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaOnePairV2_referral() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.referralAddress = referral;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), BUSD), 0);
        assertGt(feeContract.profit(referral, BUSD), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaTwoPairsV3() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaTwoPairsV2() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_Cake;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaTwoPairsV2AndV3_referral() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;
        data.referralAddress = referral;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
        assertGt(feeContract.profit(referral, CAKE), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaThreePairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), USDC), 0);
    }

    function test_multiswapRouter_multiswapWithNative_swapViaFourPairs() external {
        IMultiswapRouterFacet.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;
        data.pairs[3] = USDC_CAKE_Cake;

        hoax(user);
        router.multiswap{ value: 500_000_000 }(data, user);

        assertGt(feeContract.profit(address(feeContract), CAKE), 0);
    }
}
