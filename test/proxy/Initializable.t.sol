// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { Initializable } from "../../src/proxy/Initializable.sol";

contract MockInitializable is Initializable {
    function getVersion() external view returns (uint8) {
        return _getInitializedVersion();
    }

    // disableInitializers

    function disableInitializers_revertIfInitializing() external initializer {
        _disableInitializers();
    }

    function disableInitializers() external {
        _disableInitializers();
    }
}

contract InitializableTest is Test {
    MockInitializable mock;

    function setUp() external {
        mock = new MockInitializable();
    }

    function test_initializable_disableInitializers_shouldRevertIfInitializing() external {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        mock.disableInitializers_revertIfInitializing();
    }

    event Initialized(uint8 version);

    function test_initializable_disableInitializers_shouldEmitEvent() external {
        vm.expectEmit();
        emit Initialized(255);
        mock.disableInitializers();

        assertEq(mock.getVersion(), 255);
    }

    function test_initializable_disableInitializers_shouldDoNothing() external {
        vm.expectEmit();
        emit Initialized(255);
        mock.disableInitializers();

        assertEq(mock.getVersion(), 255);

        mock.disableInitializers();
        assertEq(mock.getVersion(), 255);
    }
}
