// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { MultiswapRouter, IMultiswapRouter } from "src/MultiswapRouter.sol";
import { IOwnable } from "src/external/IOwnable.sol";
import { Proxy } from "../src/proxy/Proxy.sol";
import "./Helpers.t.sol";

contract Partswap is Test {
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

    function test_multiswapRouter_partswap_swapViaOnePairV3() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV2() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 500_000_000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500_000_000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(router), type(uint256).max);

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV3_referral() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);
        assertGt(router.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaOnePairV2_referral() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);
        assertGt(router.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV3() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV2() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV2AndV3_referral() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);
        assertGt(router.profit(referral, BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaThreePairs() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaFourPairs() external {
        MultiswapRouter.PartswapCalldata memory data;
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

        router.partswap(data);

        assertGt(router.profit(address(router), BUSD), 0);

        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_shouldRevertWithInvalidCalldata() external {
        MultiswapRouter.PartswapCalldata memory data;
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
        vm.expectRevert(IMultiswapRouter.MultiswapRouter_InvalidPartswapCalldata.selector);
        router.partswap(data);

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
        vm.expectRevert(IMultiswapRouter.MultiswapRouter_InvalidPartswapCalldata.selector);
        router.partswap(data);

        vm.stopPrank();
    }
}
