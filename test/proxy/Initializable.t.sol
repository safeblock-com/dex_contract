// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BaseTest, Initializable } from "../BaseTest.t.sol";

contract MockInitializable is Initializable {
    function getVersion() external view returns (uint8) {
        return _getInitializedVersion();
    }

    uint256 public a;

    // disableInitializers

    function disableInitializers_revertIfInitializing() external initializer {
        _disableInitializers();
    }

    function disableInitializers() external {
        _disableInitializers();
    }

    // initializer

    function initialize() external initializer {
        a = 1;
    }

    // reinitializer

    function reintialize() external reinitializer(2) {
        a = 2;
    }
}

contract InitializableTest is BaseTest {
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
        emit Initialized({ version: 255 });
        mock.disableInitializers();

        assertEq(mock.getVersion(), 255);
    }

    function test_initializable_disableInitializers_shouldDoNothing() external {
        vm.expectEmit();
        emit Initialized({ version: 255 });
        mock.disableInitializers();

        assertEq(mock.getVersion(), 255);

        mock.disableInitializers();
        assertEq(mock.getVersion(), 255);
    }

    function test_initializable_initialize_shouldInitialize() external {
        assertEq(mock.getVersion(), 0);
        mock.initialize();

        assertEq(mock.getVersion(), 1);

        assertEq(mock.a(), 1);
    }

    function test_initializable_reinitialize_shouldReinitialize() external {
        vm.expectEmit();
        emit Initialized({ version: 1 });
        mock.initialize();
        assertEq(mock.getVersion(), 1);
        assertEq(mock.a(), 1);

        vm.expectEmit();
        emit Initialized({ version: 2 });
        mock.reintialize();
        assertEq(mock.getVersion(), 2);
        assertEq(mock.a(), 2);
    }
}
