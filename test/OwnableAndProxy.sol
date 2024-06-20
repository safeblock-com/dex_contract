// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { Solarray } from "solarray/Solarray.sol";

import { IOwnable2Step } from "../src/external/IOwnable2Step.sol";
import { EntryPoint, IEntryPoint, Initializable } from "../src/EntryPoint.sol";
import { IOwnable } from "../src/external/Ownable.sol";
import { FeeContract, IFeeContract } from "../src/FeeContract.sol";
import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { UUPSUpgradeable, ERC1967Utils } from "../src/proxy/UUPSUpgradeable.sol";

contract NoPayableRecipient { }

contract NewImplementation is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override { }
}

contract OwnableAndProxyTest is Test {
    address owner = makeAddr("owner");
    FeeContract feeContract;

    address wrappedNative = makeAddr("wrappedNative");

    EntryPoint entryPoint;

    bytes32 beaconProxyInitCodeHash;

    address logic;

    IERC20 mockERC20 = IERC20(address(deployMockERC20("mockERC20", "MockERC20", 18)));

    function setUp() external {
        startHoax(owner);
        feeContract = new FeeContract(owner);

        address entryPointImplementation = address(new EntryPoint(bytes("")));
        entryPoint = EntryPoint(payable(address(new Proxy())));

        InitialImplementation(address(entryPoint)).upgradeTo(
            entryPointImplementation, abi.encodeCall(EntryPoint.initialize, (owner, new bytes[](0)))
        );
        vm.stopPrank();
    }

    // =========================
    // initializer
    // =========================

    function test_entryPoint_disableInitializers(address newOwner) external {
        EntryPoint entryPointImplementation = new EntryPoint(bytes(""));

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        entryPointImplementation.initialize(newOwner, new bytes[](0));
    }

    function test_entryPoint_initialize_cannotBeInitializedAgain(address newOwner) external {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        entryPoint.initialize(newOwner, new bytes[](0));
    }

    function test_entryPoint_initialize_shouldInitializeContract(address newOwner) external {
        assumeNotZeroAddress(newOwner);

        EntryPoint _entryPoint = EntryPoint(payable(address(new Proxy())));
        InitialImplementation(address(_entryPoint)).upgradeTo(
            address(new EntryPoint(bytes(""))), abi.encodeCall(EntryPoint.initialize, (newOwner, new bytes[](0)))
        );
        assertEq(_entryPoint.owner(), newOwner);
    }

    // =========================
    // ownable
    // =========================

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function test_entryPointOwnable2Step_shouldRevertIfNotOwner(address notOwner) external {
        vm.assume(notOwner != owner);

        vm.startPrank(notOwner);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        entryPoint.renounceOwnership();

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        entryPoint.transferOwnership(notOwner);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.changeProtocolFee(123);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.changeReferralFee(IFeeContract.ReferralFee({ protocolPart: 50, referralPart: 50 }));

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.collectProtocolFees(address(0), address(1), 1);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        feeContract.collectProtocolFees(address(0), address(1));

        vm.stopPrank();
    }

    function test_entryPointOwnable2Step_renounceOwnership_shouldRenounceOwnership() external {
        assertEq(entryPoint.owner(), owner);

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferred(owner, address(0));
        entryPoint.renounceOwnership();

        assertEq(entryPoint.owner(), address(0));
    }

    function test_entryPointOwnable2Step_transferOwnership_shouldRevertIfNewOwnerIsAddressZero() external {
        assertEq(entryPoint.owner(), owner);

        vm.prank(owner);
        vm.expectRevert(IOwnable2Step.Ownable_NewOwnerCannotBeAddressZero.selector);
        entryPoint.transferOwnership(address(0));
    }

    function test_entryPointOwnable2Step_transferOwnership_shouldStartTransferOwnership(address newOwner) external {
        assumeNotZeroAddress(newOwner);

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, newOwner);
        entryPoint.transferOwnership(newOwner);

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
        assumeNotZeroAddress(pendingOwner);

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, pendingOwner);
        entryPoint.transferOwnership(pendingOwner);

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), pendingOwner);

        vm.prank(notPendingOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable2Step.Ownable_CallerIsNotTheNewOwner.selector, notPendingOwner));
        entryPoint.acceptOwnership();
    }

    function test_entryPointOwnable2Step_acceptOwnership_shouldTransferOwnership(address pendingOwner) external {
        assumeNotZeroAddress(pendingOwner);

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, pendingOwner);
        entryPoint.transferOwnership(pendingOwner);

        assertEq(entryPoint.owner(), owner);
        assertEq(entryPoint.pendingOwner(), pendingOwner);

        vm.prank(pendingOwner);
        vm.expectEmit();
        emit OwnershipTransferred(owner, pendingOwner);
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

        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        entryPoint.upgradeTo(impl);
    }

    event Upgraded(address indexed implementation);

    function test_entryPoint_upgradeImplementation_shouldUpgradeImplementation() external {
        address impl = address(new NewImplementation());

        vm.prank(owner);
        vm.expectEmit();
        emit Upgraded(impl);
        entryPoint.upgradeTo(impl);

        address impl_ = address(uint160(uint256(vm.load(address(entryPoint), ERC1967Utils.IMPLEMENTATION_SLOT))));

        assertEq(impl_, impl);
    }

    // =========================
    // changeFees
    // =========================

    function test_feeContract_changeFees_shouldRevertIfDataInvalid() external {
        vm.prank(owner);
        vm.expectRevert(IFeeContract.FeeContract_InvalidFeeValue.selector);
        feeContract.changeProtocolFee(10_001);

        vm.prank(owner);
        vm.expectRevert(IFeeContract.FeeContract_InvalidFeeValue.selector);
        feeContract.changeReferralFee(IFeeContract.ReferralFee({ protocolPart: 300, referralPart: 1 }));
    }

    function test_feeContract_changeFees_shouldSuccessfulChangeFees(
        uint256 newPotocolFee,
        IFeeContract.ReferralFee memory newReferralFee
    )
        external
    {
        newPotocolFee = bound(newPotocolFee, 300, 10_000);
        newReferralFee.protocolPart = bound(newReferralFee.protocolPart, 10, 200);
        newReferralFee.referralPart = bound(newReferralFee.referralPart, 10, 50);

        vm.startPrank(owner);
        feeContract.changeProtocolFee(newPotocolFee);
        feeContract.changeReferralFee(newReferralFee);

        (uint256 protocolFee, IFeeContract.ReferralFee memory referralFee) = feeContract.fees();

        assertEq(protocolFee, newPotocolFee);
        assertEq(referralFee.protocolPart, newReferralFee.protocolPart);
        assertEq(referralFee.referralPart, newReferralFee.referralPart);
    }
}
