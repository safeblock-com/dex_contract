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

    function test_multiswapRouter_multiswap_swapViaOnePairV3() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV2() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV3_refferal()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.refferalAddress = address(123);

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        assertGt(multiswapRouter.profit(address(123), BUSD), 0);
    }

    function test_multiswapRouter_multiswap_swapViaOnePairV2_refferal()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.refferalAddress = address(123);

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
        assertGt(multiswapRouter.profit(address(123), BUSD), 0);
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV3() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV2() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaTwoPairsV2AndV3_refferal()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](2);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_CAKE_CakeV3_100;
        data.refferalAddress = address(123);

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), CAKE), 0);
        assertGt(multiswapRouter.profit(address(123), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaThreePairs() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](3);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), USDC), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap_swapViaFourPairs() external {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_Cake;
        data.pairs[1] = BUSD_USDT_CakeV3_500;
        data.pairs[2] = USDT_USDC_CakeV3_500;
        data.pairs[3] = USDC_CAKE_Cake;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.multiswap(data);

        assertGt(multiswapRouter.profit(address(multiswapRouter), CAKE), 0);
        vm.stopPrank();
    }

    function test_multiswapRouter_collectProtocolFees_shouldWithdrawPartOfFees()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        uint256 fees = multiswapRouter.profit(address(multiswapRouter), BUSD);

        assertGt(fees, 0);

        vm.prank(address(1));
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_SenderIsNotOwner.selector
        );
        multiswapRouter.collectProtocolFees(BUSD, address(1), fees / 2);

        vm.prank(user);
        multiswapRouter.collectProtocolFees(BUSD, user, fees / 2);

        assertEq(
            multiswapRouter.profit(address(multiswapRouter), BUSD),
            fees / 2
        );
    }

    function test_multiswapRouter_collectProtocolFees_shouldWithdrawAllFees()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        uint256 fees = multiswapRouter.profit(address(multiswapRouter), BUSD);

        assertGt(fees, 0);

        vm.prank(address(1));
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_SenderIsNotOwner.selector
        );
        multiswapRouter.collectProtocolFees(BUSD, address(1));

        vm.prank(user);
        multiswapRouter.collectProtocolFees(BUSD, user);

        assertEq(multiswapRouter.profit(address(multiswapRouter), BUSD), 0);
    }

    function test_multiswapRouter_collectRefferalFees_shouldWithdrawPartOfFees()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.refferalAddress = address(1212);

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        uint256 fees = multiswapRouter.profit(address(1212), BUSD);

        assertGt(fees, 0);

        // did nothing
        vm.prank(address(1));
        multiswapRouter.collectRefferalFees(BUSD, address(1), fees / 2);

        vm.prank(address(1212));
        multiswapRouter.collectRefferalFees(BUSD, user, fees / 2);

        assertEq(multiswapRouter.profit(address(1212), BUSD), fees / 2);
    }

    function test_multiswapRouter_collectRefferalFees_shouldWithdrawAllFees()
        external
    {
        MultiswapRouter.MultiswapCalldata memory data;
        data.amountIn = 500000000;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.refferalAddress = address(1212);

        vm.prank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        vm.prank(user);
        multiswapRouter.multiswap(data);

        uint256 fees = multiswapRouter.profit(address(1212), BUSD);

        assertGt(fees, 0);

        // did nothing
        vm.prank(address(1));
        multiswapRouter.collectRefferalFees(BUSD, address(1));

        vm.prank(address(1212));
        multiswapRouter.collectRefferalFees(BUSD, user);

        assertEq(multiswapRouter.profit(address(1212), BUSD), 0);
    }
}
