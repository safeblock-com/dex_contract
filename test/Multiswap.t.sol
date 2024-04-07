// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { MultiswapRouter, IMultiswapRouter } from "src/MultiswapRouter.sol";
import { IOwnable } from "src/external/IOwnable.sol";
import { Proxy } from "../src/proxy/Proxy.sol";
import "./Helpers.t.sol";

contract MultiswapTest is Test {
    MultiswapRouter router;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address referral = makeAddr("referral");

    function setUp() external {
        vm.createSelectFork(vm.envString("BNB_RPC_URL"));

        deal(WBNB, user, 500e18);

        address routerImplementation = address(new MultiswapRouter());
        router = MultiswapRouter(
            payable(
                address(
                    new Proxy(
                        routerImplementation,
                        abi.encodeCall(
                            IMultiswapRouter.initialize,
                            (300, IMultiswapRouter.ReferralFee({ protocolPart: 200, referralPart: 50 }), owner)
                        )
                    )
                )
            )
        );
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV3() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV3_referral() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        assertGt(router.profit(address(router), BUSD), 0);
        assertGt(router.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV2() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV2_referral() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        assertGt(router.profit(address(router), BUSD), 0);
        assertGt(router.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV3() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data);

        assertGt(router.profit(address(router), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV2() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data);

        assertGt(router.profit(address(router), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV2AndV3_referral() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data);

        assertGt(router.profit(address(router), CAKE), 0);
        assertGt(router.profit(referral, CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaThreePairs() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data);

        assertGt(router.profit(address(router), USDC), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaFourPairs() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;
        data.pairs[3] = USDC_CAKE_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);
        router.multiswap(data);

        assertGt(router.profit(address(router), CAKE), 0);
        vm.stopPrank();
    }

    event TransferHelperTransfer(address indexed token, address indexed from, address indexed to, uint256 value);

    function test_multiswapRouter_collectProtocolFees_shouldWithdrawPartOfFees() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        uint256 fees = router.profit(address(router), BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, address(1)));
        router.collectProtocolFees(BUSD, address(1), fees >> 1);

        vm.prank(owner);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(router), user, fees >> 1);
        router.collectProtocolFees(BUSD, user, fees >> 1);

        assertApproxEqAbs(router.profit(address(router), BUSD), fees >> 1, 2);
    }

    function test_multiswapRouter_collectProtocolFees_shouldWithdrawAllFees() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        uint256 fees = router.profit(address(router), BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        vm.prank(address(1));
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, address(1)));
        router.collectProtocolFees(BUSD, address(1));

        vm.prank(owner);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(router), user, fees);
        router.collectProtocolFees(BUSD, user);

        assertEq(router.profit(address(router), BUSD), 0);
    }

    function test_multiswapRouter_collectReferralFees_shouldWithdrawPartOfFees() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        uint256 fees = router.profit(referral, BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        // did nothing
        vm.prank(address(1));
        router.collectReferralFees(BUSD, address(1), fees >> 1);

        vm.prank(referral);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(router), user, fees >> 1);
        router.collectReferralFees(BUSD, user, fees >> 1);

        assertApproxEqAbs(router.profit(referral, BUSD), fees >> 1, 2);
    }

    function test_multiswapRouter_collectReferralFees_shouldWithdrawAllFees() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500_000_000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.referralAddress = referral;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.multiswap(data);

        uint256 fees = router.profit(referral, BUSD);
        assertGt(fees, 0);

        vm.stopPrank();

        // did nothing
        vm.prank(address(1));
        router.collectReferralFees(BUSD, address(1));

        vm.prank(referral);
        vm.expectEmit();
        emit TransferHelperTransfer(BUSD, address(router), user, fees);
        router.collectReferralFees(BUSD, user);

        assertEq(router.profit(referral, BUSD), 0);
    }
}
