// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { TransferHelper } from "../src/facets/libraries/TransferHelper.sol";

contract MockTranferHelper {
    using TransferHelper for address;

    function transferFrom(address token, address from, address to, uint256 value) external {
        TransferHelper.safeTransferFrom(token, from, to, value);
    }

    function transfer(address token, address to, uint256 value) external {
        TransferHelper.safeTransfer(token, to, value);
    }

    function approve(address token, address to, uint256 value) external {
        TransferHelper.safeApprove(token, to, value);
    }

    function getBalance(address token, address account) external view returns (uint256) {
        return TransferHelper.safeGetBalance(token, account);
    }

    function transferNative(address to, uint256 value) external {
        TransferHelper.safeTransferNative(to, value);
    }
}

contract FakeERC20 {
    bool flagReturnZero;
    bool flagRevert;
    bool flagRevertBothCalls;

    function setFlagReturnZero(bool value) external {
        flagReturnZero = value;
    }

    function setFlagRevert(bool value) external {
        flagRevert = value;
    }

    function setFlagRevertBothCalls(bool value) external {
        flagRevertBothCalls = value;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        from;
        to;
        value;

        flagReturnZero = flagReturnZero;
        flagRevert = flagRevert;

        if (flagReturnZero) {
            assembly ("memory-safe") {
                return(0, 0)
            }
        }

        if (flagRevert) {
            revert();
        }

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        to;
        value;

        flagReturnZero = flagReturnZero;
        flagRevert = flagRevert;

        if (flagReturnZero) {
            assembly ("memory-safe") {
                return(0, 0)
            }
        }

        if (flagRevert) {
            revert();
        }

        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address to, uint256 value) external returns (bool) {
        to;
        value;

        flagReturnZero = flagReturnZero;
        flagRevert = flagRevert;

        if (flagReturnZero) {
            allowance[msg.sender][to] = value;

            assembly ("memory-safe") {
                return(0, 0)
            }
        }

        if (flagRevert) {
            if (value == 0) {
                allowance[msg.sender][to] = value;
                flagRevert = false;
            } else {
                revert();
            }
        }

        if (flagRevertBothCalls) {
            revert();
        }

        allowance[msg.sender][to] = value;
        return true;
    }

    function balanceOf(address to) external view returns (uint256) {
        to;

        if (flagReturnZero) {
            assembly ("memory-safe") {
                return(0, 0)
            }
        }

        if (flagRevert) {
            revert();
        }

        return 1000;
    }
}

contract TransferHelperTest is Test {
    MockTranferHelper mock;
    FakeERC20 fakeToken;

    function setUp() external {
        mock = new MockTranferHelper();
        fakeToken = new FakeERC20();
    }

    function test_transferHelper_safeTransferFrom_shouldEmitEvent(uint256 tokenAmount) external {
        _expectERC20TransferFromCall(address(fakeToken), address(this), address(1), tokenAmount);
        mock.transferFrom(address(fakeToken), address(this), address(1), tokenAmount);

        // function return nothing (like USDT on eth mainnet)
        fakeToken.setFlagReturnZero(true);

        _expectERC20TransferFromCall(address(fakeToken), address(this), address(1), tokenAmount);
        mock.transferFrom(address(fakeToken), address(this), address(1), tokenAmount);
    }

    function test_transferHelper_safeTransferFrom_shouldRevert() external {
        fakeToken.setFlagRevert(true);
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        mock.transferFrom(address(fakeToken), address(this), address(1), 1 ether);
    }

    function test_transferHelper_safeTransfer_shouldEmitEvent(uint256 tokenAmount) external {
        _expectERC20TransferCall(address(fakeToken), address(1), tokenAmount);
        mock.transfer(address(fakeToken), address(1), tokenAmount);

        // function return nothing (like USDT on eth mainnet)
        fakeToken.setFlagReturnZero(true);

        _expectERC20TransferCall(address(fakeToken), address(1), tokenAmount);
        mock.transfer(address(fakeToken), address(1), tokenAmount);
    }

    function test_transferHelper_safeTransfer_shouldRevert() external {
        fakeToken.setFlagRevert(true);
        vm.expectRevert(TransferHelper.TransferHelper_TransferError.selector);
        mock.transfer(address(fakeToken), address(1), 1 ether);
    }

    function test_transferHelper_approve(uint256 tokenAmount) external {
        vm.assume(tokenAmount > 0);

        assertEq(fakeToken.allowance(address(mock), address(1)), 0);

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve(address(fakeToken), address(1), tokenAmount);

        assertEq(fakeToken.allowance(address(mock), address(1)), tokenAmount);

        // function return nothing (like USDT on eth mainnet)
        fakeToken.setFlagReturnZero(true);

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve(address(fakeToken), address(1), tokenAmount);

        assertEq(fakeToken.allowance(address(mock), address(1)), tokenAmount);
    }

    function test_transferHelper_approve_USDTLikeApprove(uint256 tokenAmount) external {
        // Should lower the allowance to 0 before raising it (like USDT on eth mainnet)
        assertEq(fakeToken.allowance(address(mock), address(1)), 0);

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve(address(fakeToken), address(1), tokenAmount);

        assertEq(fakeToken.allowance(address(mock), address(1)), tokenAmount);

        fakeToken.setFlagRevert(true);

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve(address(fakeToken), address(1), tokenAmount);

        assertEq(fakeToken.allowance(address(mock), address(1)), tokenAmount);
    }

    function test_transferHelper_approve_shouldRevert() external {
        fakeToken.setFlagRevertBothCalls(true);

        vm.expectRevert(TransferHelper.TransferHelper_ApproveError.selector);
        mock.approve(address(fakeToken), address(1), 1);
    }

    function test_transferHelper_safeTransferNative_shouldEmitEvent(uint256 tokenAmount) external {
        deal(address(mock), tokenAmount);

        mock.transferNative(address(1), tokenAmount);

        assertEq(address(mock).balance, 0);
    }

    function test_transferHelper_safeTransferNative_shouldRevert() external {
        vm.expectRevert(TransferHelper.TransferHelper_TransferNativeError.selector);
        mock.transferNative(address(this), 1 ether);
    }

    function test_transferHelper_safeGetBalance_shouldReturnValue() external view {
        assertEq(mock.getBalance(address(fakeToken), address(1)), 1000);
    }

    function test_transferHelper_safeGetBalance_shouldRevert() external {
        fakeToken.setFlagReturnZero(true);
        vm.expectRevert(TransferHelper.TransferHelper_GetBalanceError.selector);
        mock.getBalance(address(fakeToken), address(1));

        fakeToken.setFlagReturnZero(false);
        fakeToken.setFlagRevert(true);
        vm.expectRevert(TransferHelper.TransferHelper_GetBalanceError.selector);
        mock.getBalance(address(fakeToken), address(1));
    }

    // helpers

    function _expectERC20TransferCall(address token, address to, uint256 amount) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.transfer, (to, amount)));
    }

    function _expectERC20ApproveCall(address token, address to, uint256 amount) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (to, amount)));
    }

    function _expectERC20TransferFromCall(address token, address from, address to, uint256 amount) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
    }
}
