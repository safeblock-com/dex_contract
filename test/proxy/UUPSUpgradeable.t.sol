// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Ownable, IOwnable } from "../../src/external/Ownable.sol";
import { UUPSUpgradeable, ERC1967Utils } from "../../src/proxy/UUPSUpgradeable.sol";
import { Proxy, InitialImplementation } from "../../src/proxy/Proxy.sol";

contract Implementation is UUPSUpgradeable, Ownable {
    function initialize() external {
        if (_owner == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }

    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }
}

contract FakeImplementation {
    function proxiableUUID() external pure returns (bytes32) {
        return bytes32(0);
    }
}

contract NotUUPSImplementation { }

contract ImplementationV2 is UUPSUpgradeable, Ownable {
    uint256 public a;

    function setA(uint256 _a) external payable {
        a = _a;
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }

    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }
}

contract UUPSUpgradeableTest is Test {
    address owner = makeAddr("owner");

    address impl;
    address implV2;
    address fakeImpl;
    address notUUPSImplementation;

    address proxy;

    function setUp() external {
        impl = address(new Implementation());
        implV2 = address(new ImplementationV2());
        fakeImpl = address(new FakeImplementation());
        notUUPSImplementation = address(new NotUUPSImplementation());

        vm.startPrank(owner);
        proxy = address(new Proxy());
        InitialImplementation(proxy).upgradeTo(impl, abi.encodeCall(Implementation.initialize, ()));
        vm.stopPrank();
    }

    function test_proxy_initialImplementation_shouldUpgradeImplementation(address _owner, address _notOwner) external {
        vm.assume(_owner != _notOwner);

        bytes32 __owner;
        bytes32 slot;

        assembly {
            __owner := _owner
            slot := not(0)
        }

        vm.prank(_owner);
        InitialImplementation _proxy = InitialImplementation(address(new Proxy()));

        assertEq(vm.load(address(_proxy), slot), __owner);

        vm.prank(_notOwner);
        vm.expectRevert(abi.encodeWithSelector(InitialImplementation.NotInitialOwner.selector, _notOwner));
        _proxy.upgradeTo(address(impl), bytes(""));

        vm.prank(_owner);
        vm.expectEmit();
        emit Upgraded(impl);
        _proxy.upgradeTo(address(impl), bytes(""));

        assertEq(vm.load(address(_proxy), slot), 0);
    }

    function test_UUPSUpgradeable_proxiableUUID_shouldRevertIfCalledViaProxy(address caller) external {
        vm.assume(caller != impl);

        vm.prank(caller);
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        UUPSUpgradeable(proxy).proxiableUUID();
    }

    function test_UUPSUpgradeable_proxiableUUID_shouldReturnImplementationSlot() external view {
        assertEq(UUPSUpgradeable(impl).proxiableUUID(), ERC1967Utils.IMPLEMENTATION_SLOT);
        assertEq(UUPSUpgradeable(implV2).proxiableUUID(), ERC1967Utils.IMPLEMENTATION_SLOT);
    }

    function test_UUPSUpgradeable_upgradeTo_shouldRevertInOnlyProxyModifier() external {
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        UUPSUpgradeable(impl).upgradeTo(implV2);
    }

    function test_UUPSUpgradeable_upgradeTo_shouldRevertInAuthorizeUpgradeFunction(address notOwner) external {
        vm.assume(notOwner != owner);

        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        UUPSUpgradeable(proxy).upgradeTo(implV2);
    }

    function test_UUPSUpgradeable_upgradeTo_shouldRevertInUpgradeToUUPSFunction() external {
        bytes32 slot = FakeImplementation(fakeImpl).proxiableUUID();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(UUPSUpgradeable.UUPSUnsupportedProxiableUUID.selector, slot));
        UUPSUpgradeable(proxy).upgradeTo(fakeImpl);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1967Utils.ERC1967_InvalidImplementation.selector, notUUPSImplementation)
        );
        UUPSUpgradeable(proxy).upgradeTo(notUUPSImplementation);
    }

    event Upgraded(address indexed implementation);

    function test_UUPSUpgradeable_upgradeTo_shouldUpgradeImplementation() external {
        assertEq(Implementation(proxy).getImplementation(), impl);

        vm.expectRevert();
        ImplementationV2(proxy).setA(42);

        vm.prank(owner);
        vm.expectEmit();
        emit Upgraded(implV2);
        UUPSUpgradeable(proxy).upgradeTo(implV2);

        assertEq(Implementation(proxy).getImplementation(), implV2);

        assertEq(ImplementationV2(proxy).a(), 0);
        ImplementationV2(proxy).setA(42);
        assertEq(ImplementationV2(proxy).a(), 42);

        vm.prank(owner);
        vm.expectEmit();
        emit Upgraded(impl);
        UUPSUpgradeable(proxy).upgradeTo(impl);

        assertEq(Implementation(proxy).getImplementation(), impl);
    }
}
