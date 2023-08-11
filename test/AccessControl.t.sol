// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {MultiswapRouter} from "src/MultiswapRouter.sol";

contract MultiswapTest is Test {
    MultiswapRouter multiswapRouter;
    address owner = makeAddr("OWNER");

    function setUp() external {
        vm.createSelectFork(vm.envString("BSC_URL"));

        vm.prank(owner);
        multiswapRouter = new MultiswapRouter(
            300,
            MultiswapRouter.RefferalFee({protocolPart: 200, refferalPart: 50})
        );
    }

    function test_accessControl_shouldSetOwnerAfterDeploy() external {
        assertEq(multiswapRouter.owner(), owner);
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function test_accessControl_transferOwnership_shouldChangeOwnerAndEmitEvent()
        external
    {
        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferred(owner, address(1));
        multiswapRouter.transferOwnership(address(1));

        assertEq(multiswapRouter.owner(), address(1));
    }

    function test_accessControl_transferOwnership_onlyOwnerCanCallMethod()
        external
    {
        vm.prank(address(1));
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_SenderIsNotOwner.selector
        );
        multiswapRouter.transferOwnership(address(1));
    }

    function test_accessControl_transferOwnership_shouldRevertIfNewOwnerIsZeroAddress()
        external
    {
        vm.prank(owner);
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_NewOwnerIsZeroAddress.selector
        );
        multiswapRouter.transferOwnership(address(0));
    }

    function test_fees_shouldReturnCorrectFees() external {
        (
            uint256 protocolFee,
            MultiswapRouter.RefferalFee memory refferalFee
        ) = multiswapRouter.fees();

        assertEq(protocolFee, 300);
        assertEq(refferalFee.protocolPart, 200);
        assertEq(refferalFee.refferalPart, 50);
    }

    function test_fees_changeFees_onlyOwnerCanCallMethods() external {
        vm.prank(address(1));
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_SenderIsNotOwner.selector
        );
        multiswapRouter.changeProtocolFee(120);

        vm.prank(address(1));
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_SenderIsNotOwner.selector
        );
        multiswapRouter.changeRefferalFee(
            MultiswapRouter.RefferalFee({protocolPart: 100, refferalPart: 10})
        );
    }

    function test_fees_changeFees_shouldRevertIfDataInvalid() external {
        vm.prank(owner);
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_InvalidFeeValue.selector
        );
        multiswapRouter.changeProtocolFee(10001);

        vm.prank(owner);
        vm.expectRevert(
            MultiswapRouter.MultiswapRouter_InvalidFeeValue.selector
        );
        multiswapRouter.changeRefferalFee(
            MultiswapRouter.RefferalFee({protocolPart: 300, refferalPart: 1})
        );
    }

    function test_fees_changeFees_shouldSuccessfulChangeFees() external {
        vm.prank(owner);
        multiswapRouter.changeProtocolFee(500);

        vm.prank(owner);
        multiswapRouter.changeRefferalFee(
            MultiswapRouter.RefferalFee({protocolPart: 350, refferalPart: 100})
        );

        (
            uint256 protocolFee,
            MultiswapRouter.RefferalFee memory refferalFee
        ) = multiswapRouter.fees();

        assertEq(protocolFee, 500);
        assertEq(refferalFee.protocolPart, 350);
        assertEq(refferalFee.refferalPart, 100);
    }
}
