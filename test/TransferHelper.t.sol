// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { BaseTest, TransferHelper } from "./BaseTest.t.sol";

contract MockTranferHelper {
    using TransferHelper for address;

    function transferFrom(address token, address from, address to, uint256 value) external {
        TransferHelper.safeTransferFrom({ token: token, from: from, to: to, value: value });
    }

    function transfer(address token, address to, uint256 value) external {
        TransferHelper.safeTransfer({ token: token, to: to, value: value });
    }

    function approve(address token, address to, uint256 value) external {
        TransferHelper.safeApprove({ token: token, spender: to, value: value });
    }

    function getBalance(address token, address account) external view returns (uint256) {
        return TransferHelper.safeGetBalance({ token: token, account: account });
    }

    function transferNative(address to, uint256 value) external {
        TransferHelper.safeTransferNative({ to: to, value: value });
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

    mapping(address owner => mapping(address spender => uint256)) public allowance;

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

contract TransferHelperTest is BaseTest {
    MockTranferHelper mock;
    FakeERC20 fakeToken;

    function setUp() external {
        mock = new MockTranferHelper();
        fakeToken = new FakeERC20();
    }

    function test_transferHelper_safeTransferFrom_shouldEmitEvent(uint256 tokenAmount) external {
        _expectERC20TransferFromCall(address(fakeToken), address(this), address(1), tokenAmount);
        mock.transferFrom({ token: address(fakeToken), from: address(this), to: address(1), value: tokenAmount });

        // function return nothing (like USDT on eth mainnet)
        fakeToken.setFlagReturnZero({ value: true });

        _expectERC20TransferFromCall(address(fakeToken), address(this), address(1), tokenAmount);
        mock.transferFrom({ token: address(fakeToken), from: address(this), to: address(1), value: tokenAmount });
    }

    function test_transferHelper_safeTransferFrom_shouldRevert() external {
        fakeToken.setFlagRevert({ value: true });
        vm.expectRevert(TransferHelper.TransferHelper_TransferFromError.selector);
        mock.transferFrom({ token: address(fakeToken), from: address(this), to: address(1), value: 1 ether });
    }

    function test_transferHelper_safeTransfer_shouldEmitEvent(uint256 tokenAmount) external {
        _expectERC20TransferCall(address(fakeToken), address(1), tokenAmount);
        mock.transfer({ token: address(fakeToken), to: address(1), value: tokenAmount });

        // function return nothing (like USDT on eth mainnet)
        fakeToken.setFlagReturnZero({ value: true });

        _expectERC20TransferCall(address(fakeToken), address(1), tokenAmount);
        mock.transfer({ token: address(fakeToken), to: address(1), value: tokenAmount });
    }

    function test_transferHelper_safeTransfer_shouldRevert() external {
        fakeToken.setFlagRevert({ value: true });
        vm.expectRevert(TransferHelper.TransferHelper_TransferError.selector);
        mock.transfer({ token: address(fakeToken), to: address(1), value: 1 ether });
    }

    function test_transferHelper_approve(uint256 tokenAmount) external {
        vm.assume(tokenAmount > 0);

        assertEq(fakeToken.allowance({ owner: address(mock), spender: address(1) }), 0);

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve({ token: address(fakeToken), to: address(1), value: tokenAmount });

        assertEq(fakeToken.allowance({ owner: address(mock), spender: address(1) }), tokenAmount);

        // function return nothing (like USDT on eth mainnet)
        fakeToken.setFlagReturnZero({ value: true });

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve({ token: address(fakeToken), to: address(1), value: tokenAmount });

        assertEq(fakeToken.allowance({ owner: address(mock), spender: address(1) }), tokenAmount);
    }

    function test_transferHelper_approve_USDTLikeApprove(uint256 tokenAmount) external {
        // Should lower the allowance to 0 before raising it (like USDT on eth mainnet)
        assertEq(fakeToken.allowance({ owner: address(mock), spender: address(1) }), 0);

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve({ token: address(fakeToken), to: address(1), value: tokenAmount });

        assertEq(fakeToken.allowance({ owner: address(mock), spender: address(1) }), tokenAmount);

        fakeToken.setFlagRevert({ value: true });

        _expectERC20ApproveCall(address(fakeToken), address(1), tokenAmount);
        mock.approve({ token: address(fakeToken), to: address(1), value: tokenAmount });

        assertEq(fakeToken.allowance({ owner: address(mock), spender: address(1) }), tokenAmount);
    }

    function test_transferHelper_approve_shouldRevert() external {
        fakeToken.setFlagRevertBothCalls({ value: true });

        vm.expectRevert(TransferHelper.TransferHelper_ApproveError.selector);
        mock.approve({ token: address(fakeToken), to: address(1), value: 1 });
    }

    function test_transferHelper_safeTransferNative_shouldEmitEvent(uint256 tokenAmount) external {
        deal(address(mock), tokenAmount);

        mock.transferNative({ to: address(1), value: tokenAmount });

        assertEq(address(mock).balance, 0);
    }

    function test_transferHelper_safeTransferNative_shouldRevert() external {
        vm.expectRevert(TransferHelper.TransferHelper_TransferNativeError.selector);
        mock.transferNative({ to: address(this), value: 1 ether });
    }

    function test_transferHelper_safeGetBalance_shouldReturnValue() external view {
        assertEq(mock.getBalance({ token: address(fakeToken), account: address(1) }), 1000);
    }

    function test_transferHelper_safeGetBalance_shouldRevert() external {
        fakeToken.setFlagReturnZero({ value: true });
        vm.expectRevert(TransferHelper.TransferHelper_GetBalanceError.selector);
        mock.getBalance({ token: address(fakeToken), account: address(1) });

        fakeToken.setFlagReturnZero({ value: false });
        fakeToken.setFlagRevert({ value: true });
        vm.expectRevert(TransferHelper.TransferHelper_GetBalanceError.selector);
        mock.getBalance({ token: address(fakeToken), account: address(1) });
    }
}
