// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { ERC1967Utils } from "../../src/proxy/libraries/ERC1967Utils.sol";

contract Implementation { }

contract ImplementationV2 {
    uint256 public a;

    function setA(uint256 _a) external payable {
        if (a == 0) {
            a = _a;
        } else {
            revert("a already setted");
        }
    }
}

contract ERC1967UtilsMock {
    uint256 public a;

    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function setImplementation(address implAddress) external {
        ERC1967Utils.setImplementation(implAddress);
    }

    function upgradeToAndCall(address newImpl, bytes memory data) external payable {
        ERC1967Utils.upgradeToAndCall(newImpl, data);
    }
}

contract ERC1967UtilsTest is Test {
    address impl;
    address implV2;

    ERC1967UtilsMock mock;

    function setUp() external {
        impl = address(new Implementation());
        implV2 = address(new ImplementationV2());

        mock = new ERC1967UtilsMock();
    }

    function test_ERC1967Utils_shouldRevertIfImplNotAContract(address noCodeImplementation) external {
        vm.assume(noCodeImplementation.code.length == 0);

        assertEq(mock.getImplementation(), address(0));

        vm.expectRevert(
            abi.encodeWithSelector(ERC1967Utils.ERC1967_InvalidImplementation.selector, noCodeImplementation)
        );
        mock.setImplementation(noCodeImplementation);

        vm.expectRevert(
            abi.encodeWithSelector(ERC1967Utils.ERC1967_InvalidImplementation.selector, noCodeImplementation)
        );
        mock.upgradeToAndCall(noCodeImplementation, bytes(""));
    }

    function test_ERC1967Utils_setImplementation_shouldSetNewImplementation() external {
        assertEq(mock.getImplementation(), address(0));

        mock.setImplementation(impl);

        assertEq(mock.getImplementation(), impl);
    }

    event Upgraded(address indexed implementation);

    function test_ERC1967Utils_upgradeToAndCall_shouldRevertIfDataNotProvidedButSendValue(uint256 value) external {
        vm.assume(value > 0);
        deal(address(this), value);

        vm.expectRevert(ERC1967Utils.ERC1967_NonPayable.selector);
        mock.upgradeToAndCall{ value: value }(impl, bytes(""));
    }

    function test_ERC1967Utils_upgradeToAndCall_shouldRevertIfCallFailed(bytes memory data) external {
        vm.assume(data.length > 0);

        vm.expectRevert(ERC1967Utils.ERC1967_FailedInnerCall.selector);
        mock.upgradeToAndCall(impl, data);
    }

    function test_ERC1967Utils_upgradeToAndCall_shouldUpgrade() external {
        assertEq(mock.getImplementation(), address(0));

        vm.expectEmit();
        emit Upgraded(impl);
        mock.upgradeToAndCall(impl, bytes(""));

        assertEq(mock.getImplementation(), impl);

        bytes memory data = abi.encodeCall(ImplementationV2.setA, (42));

        vm.expectEmit();
        emit Upgraded(implV2);
        mock.upgradeToAndCall(implV2, data);

        assertEq(mock.getImplementation(), implV2);
        assertEq(mock.a(), 42);
    }

    function test_ERC1967Utils_upgradeToAndCall_shouldReturnError() external {
        bytes memory data = abi.encodeCall(ImplementationV2.setA, (42));

        vm.expectEmit();
        emit Upgraded(implV2);
        mock.upgradeToAndCall(implV2, data);

        assertEq(mock.getImplementation(), implV2);

        vm.expectRevert("a already setted");
        mock.upgradeToAndCall(implV2, data);
    }
}
