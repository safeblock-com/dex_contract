// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
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
        multiswapRouter = new MultiswapRouter();
    }

    function test_multiswapRouter_multiswap_swapViaOnePair() external {
        MultiswapRouter.Calldata memory data;
        data.amountIn = 10e18;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](1);

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);

        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_UniV3_500;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_UniV3_100;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_CakeV3_10000;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_CakeV3_500;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_CakeV3_100;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_Cake;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_BUSD_Biswap;
        multiswapRouter.multiswap(data);

        data.pairs[0] = WBNB_ETH_Bakery;
        multiswapRouter.multiswap(data);
        vm.stopPrank();
    }

    function test_multiswapRouter_multiswap() external {
        MultiswapRouter.Calldata memory data;
        data.amountIn = 10e18;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.pairs[1] = BUSD_USDT_UniV3_500;
        data.pairs[2] = WBNB_USDT_Cake;
        data.pairs[3] = WBNB_ETH_Biswap;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.multiswap(data);
        vm.stopPrank();
    }

    function test_multiswapRouter_partswap() external {
        MultiswapRouter.CalldataPartswap memory data;
        data.fullAmount = 10e18;
        data.tokenIn = WBNB;
        data.pairs = new bytes32[](4);
        data.pairs[0] = WBNB_BUSD_UniV3_3000;
        data.pairs[1] = WBNB_BUSD_CakeV3_10000;
        data.pairs[2] = WBNB_BUSD_Cake;
        data.pairs[3] = WBNB_BUSD_Bakery;
        data.amountsIn = new uint256[](4);
        data.amountsIn[0] = 2.5e18;
        data.amountsIn[1] = 2.5e18;
        data.amountsIn[2] = 2.5e18;
        data.amountsIn[3] = 2.5e18;

        vm.startPrank(user);
        IERC20(WBNB).approve(address(multiswapRouter), type(uint256).max);
        multiswapRouter.partSwap(data);
        vm.stopPrank();
    }
}
