// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { UUPSUpgradeable, ERC1967Utils } from "../../src/proxy/UUPSUpgradeable.sol";

import { BaseTest, Proxy, InitialImplementation, Ownable, IOwnable } from "../BaseTest.t.sol";

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

contract UUPSUpgradeableTest is BaseTest {
    address impl;
    address implV2;
    address fakeImpl;
    address notUUPSImplementation;

    address proxy;

    function setUp() external {
        _createUsers();

        _resetPrank(owner);

        impl = address(new Implementation());
        implV2 = address(new ImplementationV2());
        fakeImpl = address(new FakeImplementation());
        notUUPSImplementation = address(new NotUUPSImplementation());

        proxy = address(new Proxy({ initialOwner: owner }));
        InitialImplementation(proxy).upgradeTo({
            implementation: impl,
            data: abi.encodeCall(Implementation.initialize, ())
        });
    }

    function test_proxy_initialImplementation_shouldUpgradeImplementation(address _owner, address _notOwner) external {
        vm.assume(_owner != _notOwner);

        bytes32 __owner;
        bytes32 slot;

        assembly {
            __owner := _owner
            slot := not(0)
        }

        _resetPrank(_owner);
        InitialImplementation _proxy = InitialImplementation(address(new Proxy({ initialOwner: _owner })));

        assertEq(vm.load(address(_proxy), slot), __owner);

        _resetPrank(_notOwner);
        vm.expectRevert(abi.encodeWithSelector(InitialImplementation.NotInitialOwner.selector, _notOwner));
        _proxy.upgradeTo({ implementation: address(impl), data: bytes("") });

        _resetPrank(_owner);
        vm.expectEmit();
        emit Upgraded({ implementation: impl });
        _proxy.upgradeTo({ implementation: address(impl), data: bytes("") });

        assertEq(vm.load(address(_proxy), slot), 0);
    }

    function test_UUPSUpgradeable_proxiableUUID_shouldRevertIfCalledViaProxy(address caller) external {
        vm.assume(caller != impl);

        _resetPrank(caller);
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        UUPSUpgradeable(proxy).proxiableUUID();
    }

    function test_UUPSUpgradeable_proxiableUUID_shouldReturnImplementationSlot() external view {
        assertEq(UUPSUpgradeable(impl).proxiableUUID(), ERC1967Utils.IMPLEMENTATION_SLOT);
        assertEq(UUPSUpgradeable(implV2).proxiableUUID(), ERC1967Utils.IMPLEMENTATION_SLOT);
    }

    function test_UUPSUpgradeable_upgradeTo_shouldRevertInOnlyProxyModifier() external {
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        UUPSUpgradeable(impl).upgradeTo({ newImplementation: implV2 });
    }

    function test_UUPSUpgradeable_upgradeTo_shouldRevertInAuthorizeUpgradeFunction(address notOwner) external {
        vm.assume(notOwner != owner);

        _resetPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        UUPSUpgradeable(proxy).upgradeTo({ newImplementation: implV2 });
    }

    function test_UUPSUpgradeable_upgradeTo_shouldRevertInUpgradeToUUPSFunction() external {
        bytes32 slot = FakeImplementation(fakeImpl).proxiableUUID();

        _resetPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(UUPSUpgradeable.UUPSUnsupportedProxiableUUID.selector, slot));
        UUPSUpgradeable(proxy).upgradeTo({ newImplementation: fakeImpl });

        _resetPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1967Utils.ERC1967_InvalidImplementation.selector, notUUPSImplementation)
        );
        UUPSUpgradeable(proxy).upgradeTo({ newImplementation: notUUPSImplementation });
    }

    event Upgraded(address indexed implementation);

    function test_UUPSUpgradeable_upgradeTo_shouldUpgradeImplementation() external {
        assertEq(Implementation(proxy).getImplementation(), impl);

        vm.expectRevert();
        ImplementationV2(proxy).setA({ _a: 42 });

        _resetPrank(owner);
        vm.expectEmit();
        emit Upgraded({ implementation: implV2 });
        UUPSUpgradeable(proxy).upgradeTo({ newImplementation: implV2 });

        assertEq(Implementation(proxy).getImplementation(), implV2);

        assertEq(ImplementationV2(proxy).a(), 0);
        ImplementationV2(proxy).setA({ _a: 42 });
        assertEq(ImplementationV2(proxy).a(), 42);

        _resetPrank(owner);
        vm.expectEmit();
        emit Upgraded({ implementation: impl });
        UUPSUpgradeable(proxy).upgradeTo({ newImplementation: impl });

        assertEq(Implementation(proxy).getImplementation(), impl);
    }
}
