// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { IOwnable2Step } from "../src/external/IOwnable2Step.sol";
import { MultiswapRouter, IMultiswapRouter, Initializable } from "../src/MultiswapRouter.sol";
import { IOwnable } from "../src/external/Ownable.sol";
import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { UUPSUpgradeable, ERC1967Utils } from "../src/proxy/UUPSUpgradeable.sol";

contract NoPayableRecipient { }

contract NewImplementation is UUPSUpgradeable {
    function _authorizeUpgrade(address) internal override { }
}

contract FactoryTest is Test {
    address owner = makeAddr("owner");

    address wrappedNative = makeAddr("wrappedNative");

    MultiswapRouter router;

    bytes32 beaconProxyInitCodeHash;

    address logic;

    IERC20 mockERC20 = IERC20(address(deployMockERC20("mockERC20", "MockERC20", 18)));

    function setUp() external {
        address routerImplementation = address(new MultiswapRouter(wrappedNative));

        router = MultiswapRouter(payable(address(new Proxy())));

        InitialImplementation(address(router)).upgradeTo(
            routerImplementation,
            abi.encodeCall(
                IMultiswapRouter.initialize,
                (300, IMultiswapRouter.ReferralFee({ protocolPart: 200, referralPart: 50 }), owner)
            )
        );
    }

    // =========================
    // initializer
    // =========================

    function test_multiswapRouter_disableInitializers(
        uint256 protocolFee,
        IMultiswapRouter.ReferralFee memory referralFee,
        address newOwner
    )
        external
    {
        protocolFee = bound(protocolFee, 300, 10_000);
        referralFee.protocolPart = bound(referralFee.protocolPart, 10, 200);
        referralFee.referralPart = bound(referralFee.referralPart, 10, 50);

        MultiswapRouter _router = new MultiswapRouter(wrappedNative);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _router.initialize(protocolFee, referralFee, newOwner);
    }

    function test_multiswapRouter_initialize_cannotBeInitializedAgain(
        uint256 protocolFee,
        IMultiswapRouter.ReferralFee memory referralFee,
        address newOwner
    )
        external
    {
        protocolFee = bound(protocolFee, 300, 10_000);
        referralFee.protocolPart = bound(referralFee.protocolPart, 10, 200);
        referralFee.referralPart = bound(referralFee.referralPart, 10, 50);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        router.initialize(protocolFee, referralFee, newOwner);
    }

    function test_multiswapRouter_initialize_shouldInitializeContract(
        uint256 protocolFee,
        IMultiswapRouter.ReferralFee memory referralFee,
        address newOwner
    )
        external
    {
        assumeNotZeroAddress(newOwner);

        protocolFee = bound(protocolFee, 300, 10_000);
        referralFee.protocolPart = bound(referralFee.protocolPart, 10, 200);
        referralFee.referralPart = bound(referralFee.referralPart, 10, 50);

        MultiswapRouter _router = MultiswapRouter(payable(address(new Proxy())));
        InitialImplementation(address(_router)).upgradeTo(
            address(new MultiswapRouter(wrappedNative)),
            abi.encodeCall(IMultiswapRouter.initialize, (protocolFee, referralFee, newOwner))
        );

        (uint256 _protocolFee, IMultiswapRouter.ReferralFee memory _referralFee) = _router.fees();

        assertEq(_protocolFee, protocolFee);
        assertEq(_referralFee.protocolPart, referralFee.protocolPart);
        assertEq(_referralFee.referralPart, referralFee.referralPart);
        assertEq(_router.owner(), newOwner);
    }

    // =========================
    // ownable
    // =========================

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function test_multiswapRouterOwnable2Step_shouldRevertIfNotOwner(address notOwner) external {
        vm.assume(notOwner != owner);

        vm.startPrank(notOwner);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        router.renounceOwnership();

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        router.transferOwnership(notOwner);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        router.changeProtocolFee(123);

        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        router.changeReferralFee(IMultiswapRouter.ReferralFee({ protocolPart: 50, referralPart: 50 }));

        vm.stopPrank();
    }

    function test_multiswapRouterOwnable2Step_renounceOwnership_shouldRenounceOwnership() external {
        assertEq(router.owner(), owner);

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferred(owner, address(0));
        router.renounceOwnership();

        assertEq(router.owner(), address(0));
    }

    function test_multiswapRouterOwnable2Step_transferOwnership_shouldRevertIfNewOwnerIsAddressZero() external {
        assertEq(router.owner(), owner);

        vm.prank(owner);
        vm.expectRevert(IOwnable2Step.Ownable_NewOwnerCannotBeAddressZero.selector);
        router.transferOwnership(address(0));
    }

    function test_multiswapRouterOwnable2Step_transferOwnership_shouldStartTransferOwnership(address newOwner)
        external
    {
        assumeNotZeroAddress(newOwner);

        assertEq(router.owner(), owner);
        assertEq(router.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, newOwner);
        router.transferOwnership(newOwner);

        assertEq(router.owner(), owner);
        assertEq(router.pendingOwner(), newOwner);
    }

    function test_multiswapRouterOwnable2Step_acceptOwnership_shouldRevertIfSenderIsNotPendingOwner(
        address pendingOwner,
        address notPendingOwner
    )
        external
    {
        vm.assume(pendingOwner != notPendingOwner);
        assumeNotZeroAddress(pendingOwner);

        assertEq(router.owner(), owner);
        assertEq(router.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, pendingOwner);
        router.transferOwnership(pendingOwner);

        assertEq(router.owner(), owner);
        assertEq(router.pendingOwner(), pendingOwner);

        vm.prank(notPendingOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable2Step.Ownable_CallerIsNotTheNewOwner.selector, notPendingOwner));
        router.acceptOwnership();
    }

    function test_multiswapRouterOwnable2Step_acceptOwnership_shouldTransferOwnership(address pendingOwner) external {
        assumeNotZeroAddress(pendingOwner);

        assertEq(router.owner(), owner);
        assertEq(router.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectEmit();
        emit OwnershipTransferStarted(owner, pendingOwner);
        router.transferOwnership(pendingOwner);

        assertEq(router.owner(), owner);
        assertEq(router.pendingOwner(), pendingOwner);

        vm.prank(pendingOwner);
        vm.expectEmit();
        emit OwnershipTransferred(owner, pendingOwner);
        router.acceptOwnership();

        assertEq(router.owner(), pendingOwner);
        assertEq(router.pendingOwner(), address(0));
    }

    // =========================
    // proxy
    // =========================

    function test_multiswapRouter_upgradeImplementation_shouldRevertIfSenderIsNotOwner(address notOwner) external {
        vm.assume(owner != notOwner);

        address impl = address(new NewImplementation());

        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable_SenderIsNotOwner.selector, notOwner));
        router.upgradeTo(impl);
    }

    event Upgraded(address indexed implementation);

    function test_multiswapRouter_upgradeImplementation_shouldUpgradeImplementation() external {
        address impl = address(new NewImplementation());

        vm.prank(owner);
        vm.expectEmit();
        emit Upgraded(impl);
        router.upgradeTo(impl);

        address impl_ = address(uint160(uint256(vm.load(address(router), ERC1967Utils.IMPLEMENTATION_SLOT))));

        assertEq(impl_, impl);
    }

    // =========================
    // changeFees
    // =========================

    function test_multiswapRouter_changeFees_shouldRevertIfDataInvalid() external {
        vm.prank(owner);
        vm.expectRevert(IMultiswapRouter.MultiswapRouter_InvalidFeeValue.selector);
        router.changeProtocolFee(10_001);

        vm.prank(owner);
        vm.expectRevert(IMultiswapRouter.MultiswapRouter_InvalidFeeValue.selector);
        router.changeReferralFee(IMultiswapRouter.ReferralFee({ protocolPart: 300, referralPart: 1 }));
    }

    function test_multiswapRouter_changeFees_shouldSuccessfulChangeFees(
        uint256 newPotocolFee,
        IMultiswapRouter.ReferralFee memory newReferralFee
    )
        external
    {
        newPotocolFee = bound(newPotocolFee, 300, 10_000);
        newReferralFee.protocolPart = bound(newReferralFee.protocolPart, 10, 200);
        newReferralFee.referralPart = bound(newReferralFee.referralPart, 10, 50);

        vm.startPrank(owner);
        router.changeProtocolFee(newPotocolFee);
        router.changeReferralFee(newReferralFee);

        (uint256 protocolFee, IMultiswapRouter.ReferralFee memory referralFee) = router.fees();

        assertEq(protocolFee, newPotocolFee);
        assertEq(referralFee.protocolPart, newReferralFee.protocolPart);
        assertEq(referralFee.referralPart, newReferralFee.referralPart);
    }
}
