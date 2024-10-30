// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BaseTest, IOwnable2Step, IOwnable, EntryPoint, Initializable, IFeeContract } from "./BaseTest.t.sol";

import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { UUPSUpgradeable, ERC1967Utils } from "../src/proxy/UUPSUpgradeable.sol";

contract NoPayableRecipient { }

contract NewImplementation is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override { }
}

contract OwnableAndProxyTest is BaseTest {
    function setUp() external {
        _createUsers();

        _resetPrank(owner);

        deployForTest();
    }

    // =========================
    // initializer
    // =========================

    function test_entryPoint_disableInitializers(address newOwner) external {
        EntryPoint entryPointImplementation = new EntryPoint({ facetsAndSelectors: bytes("") });

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        entryPointImplementation.initialize({ newOwner: newOwner, initialCalls: new bytes[](0) });
    }

    function test_entryPoint_initialize_cannotBeInitializedAgain(address newOwner) external {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        entryPoint.initialize({ newOwner: newOwner, initialCalls: new bytes[](0) });
    }

    function test_entryPoint_initialize_shouldInitializeContract(address newOwner) external {
        assumeNotZeroAddress({ addr: newOwner });

        _resetPrank(owner);

        EntryPoint _entryPoint = EntryPoint(payable(address(new Proxy({ initialOwner: owner }))));
        InitialImplementation(address(_entryPoint)).upgradeTo({
            implementation: address(new EntryPoint({ facetsAndSelectors: bytes("") })),
            data: abi.encodeCall(EntryPoint.initialize, (newOwner, new bytes[](0)))
        });
        assertEq(_entryPoint.owner(), newOwner);
    }

    // =========================
    // ownable
    // =========================

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function test_entryPointOwnable2Step_shouldRevertIfNotOwner(address notOwner) external {
        vm.assume(notOwner != owner);

        _resetPrank(notOwner);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        entryPoint.renounceOwnership();

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        entryPoint.transferOwnership({ newOwner: notOwner });

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.setProtocolFee({ newProtocolFee: 123 });

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.setRouter({ newRouter: notOwner });

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.collectProtocolFees({ token: address(0), recipient: address(1), amount: 1 });
    }

    function test_entryPointOwnable2Step_renounceOwnership_shouldRenounceOwnership() external {
        assertEq(entryPoint.owner(), owner);

        _resetPrank(owner);
        vm.expectEmit();
        emit OwnershipTransferred({ previousOwner: owner, newOwner: address(0) });
        entryPoint.renounceOwnership();

        assertEq(entryPoint.owner(), address(0));
    }

    function test_entryPointOwnable2Step_transferOwnership_shouldRevertIfNewOwnerIsAddressZero() external {
        assertEq(entryPoint.owner(), owner);

        _resetPrank(owner);
        vm.expectRevert(IOwnable2Step.Ownable_NewOwnerCannotBeAddressZero.selector);
        entryPoint.transferOwnership({ newOwner: address(0) });
    }

    function test_entryPointOwnable2Step_transferOwnership_shouldStartTransferOwnership(address newOwner) external {
        assumeNotZeroAddress({ addr: newOwner });

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), address(0));

        _resetPrank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, newOwner);
        entryPoint.transferOwnership({ newOwner: newOwner });

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), newOwner);
    }

    function test_entryPointOwnable2Step_acceptOwnership_shouldRevertIfSenderIsNotPendingOwner(
        address pendingOwner,
        address notPendingOwner
    )
        external
    {
        vm.assume(pendingOwner != notPendingOwner);
        assumeNotZeroAddress({ addr: pendingOwner });

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), address(0));

        _resetPrank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, pendingOwner);
        entryPoint.transferOwnership({ newOwner: pendingOwner });

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), pendingOwner);

        _resetPrank(notPendingOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable2Step.Ownable_CallerIsNotTheNewOwner.selector, notPendingOwner));
        entryPoint.acceptOwnership();
    }

    function test_entryPointOwnable2Step_acceptOwnership_shouldTransferOwnership(address pendingOwner) external {
        assumeNotZeroAddress({ addr: pendingOwner });

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), address(0));

        _resetPrank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, pendingOwner);
        entryPoint.transferOwnership({ newOwner: pendingOwner });

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), pendingOwner);

        _resetPrank(pendingOwner);
        vm.expectEmit();
        emit OwnershipTransferred({ previousOwner: owner, newOwner: pendingOwner });
        entryPoint.acceptOwnership();

        assertEq(entryPoint.owner(), pendingOwner);
        assertEq(entryPoint.pendingOwner(), address(0));
    }

    // =========================
    // proxy
    // =========================

    function test_entryPoint_upgradeImplementation_shouldRevertIfSenderIsNotOwner(address notOwner) external {
        vm.assume(owner != notOwner);

        address impl = address(new NewImplementation());

        _resetPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        entryPoint.upgradeTo({ newImplementation: impl });
    }

    event Upgraded(address indexed implementation);

    function test_entryPoint_upgradeImplementation_shouldUpgradeImplementation() external {
        address impl = address(new NewImplementation());

        _resetPrank(owner);
        vm.expectEmit();
        emit Upgraded({ implementation: impl });
        entryPoint.upgradeTo({ newImplementation: impl });

        address impl_ = address(uint160(uint256(vm.load(address(entryPoint), ERC1967Utils.IMPLEMENTATION_SLOT))));

        assertEq(impl_, impl);
    }

    // =========================
    // changeFees
    // =========================

    function test_feeContract_changeFees_shouldRevertIfDataInvalid() external {
        _resetPrank(owner);
        vm.expectRevert(IFeeContract.FeeContract_InvalidFeeValue.selector);
        feeContract.setProtocolFee({ newProtocolFee: 1_000_001 });
    }

    function test_feeContract_changeFees_shouldSuccessfulChangeFees(uint256 newPotocolFee) external {
        newPotocolFee = bound(newPotocolFee, 300, 10_000);

        _resetPrank(owner);
        feeContract.setProtocolFee({ newProtocolFee: newPotocolFee });

        uint256 protocolFee = feeContract.fees();

        assertEq(protocolFee, newPotocolFee);
    }

    // =========================
    // setRouter
    // =========================

    function test_feeContract_setRouter_shouldSetNewRouter(address newRouter) external {
        assertEq(feeContract.router(), address(entryPoint));

        _resetPrank(owner);
        feeContract.setRouter({ newRouter: newRouter });

        assertEq(feeContract.router(), newRouter);
    }
}
