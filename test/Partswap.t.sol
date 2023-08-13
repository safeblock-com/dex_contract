// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

import {MultiswapRouter} from "src/MultiswapRouter.sol";
import "./Helpers.t.sol";

contract MultiswapTest is Test {
    MultiswapRouter multiswapRouter;
    address user = makeAddr("USER");
    address donor = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;

    function setUp() external {
        vm.createSelectFork(vm.envString("BSC_URL"));

        vm.prank(donor);
        IERC20(WBNB).transfer(user, 500e18);

        vm.prank(user);
        multiswapRouter = new MultiswapRouter(
            300,
            MultiswapRouter.RefferalFee({protocolPart: 200, refferalPart: 50})
        );
    }

    function test_multiswapRouter_partswap_swapViaOnePairV3() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 500000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500000000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
    }

    function test_multiswapRouter_partswap_swapViaOnePairV2() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 500000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500000000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
    }

    function test_multiswapRouter_partswap_swapViaOnePairV3_refferal()
        external
    {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 500000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500000000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.refferalAddress = address(123);

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        assertGt(multiswapRouter.profit(address(123), BUSD), 0);
    }

    function test_multiswapRouter_partswap_swapViaOnePairV2_refferal()
        external
    {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 500000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](1);
        data.amountsIn[0] = 500000000;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.refferalAddress = address(123);

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        assertGt(multiswapRouter.profit(address(123), BUSD), 0);
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV3() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 1000000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500000000;
        data.amountsIn[1] = 500000000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = WBNB_BUSD_UniV3_500;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV2() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 1000000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500000000;
        data.amountsIn[1] = 500000000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaTwoPairsV2AndV3_refferal()
        external
    {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 1000000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](2);
        data.amountsIn[0] = 500000000;
        data.amountsIn[1] = 500000000;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_CakeV3_500;
        data.refferalAddress = address(123);

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        assertGt(multiswapRouter.profit(address(123), BUSD), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaThreePairs() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 1500000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](3);
        data.amountsIn[0] = 500000000;
        data.amountsIn[1] = 500000000;
        data.amountsIn[2] = 500000000;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_CakeV3_10000;
        data.pairs[2] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_swapViaFourPairs() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 2000000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 500000000;
        data.amountsIn[1] = 500000000;
        data.amountsIn[2] = 500000000;
        data.amountsIn[3] = 500000000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.partswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap_shouldRevertWithInvalidCalldata() external {
        MultiswapRouter.PartswapCalldata memory data;
        data.fullAmount = 2000000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 600000000;
        data.amountsIn[1] = 500000000;
        data.amountsIn[2] = 500000000;
        data.amountsIn[3] = 500000000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        vm.expectRevert(MultiswapRouter.MultiswapRouter_InvalidPartswapCalldata.selector);
        multiswapRouter.partswap(data);

        data.fullAmount = 2000000000;
        data.tokenIn = WBNB;
        data.tokenOut = BUSD;
        data.amountsIn = new uint256[](3);
        data.amountsIn[0] = 500000000;
        data.amountsIn[1] = 500000000;
        data.amountsIn[2] = 500000000;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = WBNB_BUSD_Biswap;
        data.pairs[2] = WBNB_BUSD_CakeV3_500;
        data.pairs[3] = WBNB_BUSD_Bakery;

        vm.startPrank(user);
        vm.expectRevert(MultiswapRouter.MultiswapRouter_InvalidPartswapCalldata.selector);
        multiswapRouter.partswap(data);

        vm.stopPrank();
    }
}
