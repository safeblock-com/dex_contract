// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DeployEngine, getContracts } from "../script/DeployEngine.sol";

import { Initializable } from "../src/proxy/Initializable.sol";

import "./BaseTest.t.sol";
import "./Helpers.t.sol";

contract Facet1 {
    struct FacetStorage {
        uint256 value;
    }

    bytes32 internal constant STORAGE_POINTER = keccak256("facet1");

    function _getLocalStorage() internal pure returns (FacetStorage storage s) {
        bytes32 pointer = STORAGE_POINTER;
        assembly ("memory-safe") {
            s.slot := pointer
        }
    }

    function getValue1() external view returns (uint256) {
        return _getLocalStorage().value;
    }

    function setValue1(uint256 value) external returns (bytes32[] memory) {
        _getLocalStorage().value = value;

        return Utils.decodeTokensAndAmountsArray();
    }

    function revertMethod() external pure {
        revert("revert method");
    }

    function moduleMethod1() external pure { }

    function moduleMethod2() external pure { }
}

contract Facet2 {
    struct FacetStorage {
        uint256 value;
        uint256 value2;
    }

    bytes32 internal constant STORAGE_POINTER = keccak256("facet2");

    function _getLocalStorage() internal pure returns (FacetStorage storage s) {
        bytes32 pointer = STORAGE_POINTER;
        assembly ("memory-safe") {
            s.slot := pointer
        }
    }

    function getValue2() external view returns (uint256) {
        return _getLocalStorage().value;
    }

    function setValue2(uint256 value) external returns (bytes32[] memory) {
        _getLocalStorage().value = value;

        return Utils.decodeTokensAndAmountsArray();
    }

    function getValue3() external view returns (uint256) {
        return _getLocalStorage().value2;
    }

    function setValue3(uint256 value) external returns (bytes32[] memory) {
        _getLocalStorage().value2 = value;

        return new bytes32[](0);
    }

    function moduleMethod1() external pure { }
}

contract EntryPointTest is BaseTest {
    address facet1;
    address facet2;

    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

        contracts = getContracts({ chainId: block.chainid });

        _resetPrank(owner);

        facet1 = address(new Facet1());
        facet2 = address(new Facet2());

        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = Facet1.getValue1.selector;
        selectors[1] = Facet1.setValue1.selector;
        selectors[2] = Facet1.revertMethod.selector;
        selectors[3] = Facet2.getValue2.selector;
        selectors[4] = Facet2.setValue2.selector;
        selectors[5] = Facet2.getValue3.selector;
        selectors[6] = Facet2.setValue3.selector;

        address entryPointImplementation = address(
            new EntryPoint({
                facetsAndSelectors: DeployEngine.getBytesArray({
                    selectors: selectors,
                    addressIndexes: Solarray.uint256s(0, 0, 0, 1, 1, 1, 1),
                    facetAddresses: Solarray.addresses(facet1, facet2)
                }),
                permit2Address: contracts.permit2,
                wrappedNativeAddress: contracts.wrappedNative,
                authorizedSender: contracts.authorizedSender
            })
        );

        entryPoint = EntryPoint(payable(address(new Proxy({ initialOwner: owner }))));

        InitialImplementation(address(entryPoint)).upgradeTo({
            implementation: entryPointImplementation,
            data: abi.encodeCall(EntryPoint.initialize, (owner))
        });
    }

    // =========================
    // constructor and initializer
    // =========================

    event Initialized(uint8 version);

    function test_entryPoint_constructor_shouldDeployAndDisableInitializers() external {
        _resetPrank(owner);

        vm.expectEmit();
        emit Initialized({ version: 255 });
        EntryPoint _entryPoint = new EntryPoint({
            facetsAndSelectors: bytes(""),
            permit2Address: contracts.permit2,
            wrappedNativeAddress: contracts.wrappedNative,
            authorizedSender: contracts.authorizedSender
        });

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _entryPoint.initialize({ newOwner: owner });
    }

    // =========================
    // empty facets and selectors
    // =========================

    function test_entryPoint_shouldRevertIfFacetsAndSelectorsLengthLessThan29Bytes() external {
        address entryPointImplementation = address(
            new EntryPoint({
                facetsAndSelectors: bytes(""),
                permit2Address: contracts.permit2,
                wrappedNativeAddress: contracts.wrappedNative,
                authorizedSender: contracts.authorizedSender
            })
        );

        InitialImplementation proxy = InitialImplementation(payable(address(new Proxy({ initialOwner: owner }))));

        _resetPrank(owner);

        proxy.upgradeTo({
            implementation: entryPointImplementation,
            data: abi.encodeCall(EntryPoint.initialize, (owner))
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, Facet1.setValue1.selector)
        );
        Facet1(address(proxy)).setValue1({ value: 1 });

        IEntryPoint.TokenTransfers memory tokenTransfers;

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x00000000))
        );
        EntryPoint(payable(address(proxy))).multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeCall(Facet1.setValue1, (1)), abi.encodeCall(Facet2.setValue2, (2)))
        });
    }

    // =========================
    // setFeeContractAddress
    // =========================

    function test_entryPoint_setFeeContractAddress_shouldSetFeeContractAddressAndFee(
        address feeContractAddress,
        uint256 fee
    )
        external
    {
        assumeNotZeroAddress({ addr: feeContractAddress });
        fee = bound(fee, 1, type(uint96).max);

        (address feeContractCurrent, uint256 feeCurrent) = entryPoint.getFeeContractAddressAndFee();
        assertEq(feeContractCurrent, address(0));
        assertEq(feeCurrent, 0);

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: feeContractAddress, fee: fee });

        (feeContractCurrent, feeCurrent) = entryPoint.getFeeContractAddressAndFee();
        assertEq(feeContractCurrent, feeContractAddress);
        assertEq(feeCurrent, fee);
    }

    // =========================
    // modules
    // =========================

    function test_entryPoint_addModule_shouldAddModule(bytes4 moduleSignature, address moduleAddress) external {
        assumeNotZeroAddress({ addr: moduleAddress });
        vm.assume(moduleSignature != bytes4(0));

        _resetPrank(owner);

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignature }), address(0));

        entryPoint.addModule({ moduleSignature: moduleSignature, moduleAddress: moduleAddress });

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignature }), moduleAddress);

        IEntryPoint.ModuleInfo[] memory modules = entryPoint.getModules();

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleSignature, moduleSignature);
        assertEq(modules[0].moduleAddress, moduleAddress);
    }

    function test_entryPoint_addModule_shouldRevertIfModuleAlreadyAdded(
        bytes4 moduleSignature,
        address moduleAddress
    )
        external
    {
        assumeNotZeroAddress({ addr: moduleAddress });
        vm.assume(moduleSignature != bytes4(0));

        _resetPrank(owner);

        entryPoint.addModule({ moduleSignature: moduleSignature, moduleAddress: moduleAddress });

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignature }), moduleAddress);

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.EntryPoint_ModuleAlreadyAdded.selector, moduleSignature));
        entryPoint.addModule({ moduleSignature: moduleSignature, moduleAddress: moduleAddress });
    }

    function test_entryPoint_updateModule_shouldUpdateModule(
        bytes4 moduleSignature,
        address[2] memory moduleAddresses
    )
        external
    {
        assumeNotZeroAddress({ addr: moduleAddresses[0] });
        assumeNotZeroAddress({ addr: moduleAddresses[1] });
        vm.assume(moduleAddresses[0] != moduleAddresses[1]);
        vm.assume(moduleSignature != bytes4(0));

        _resetPrank(owner);

        entryPoint.addModule({ moduleSignature: moduleSignature, moduleAddress: moduleAddresses[0] });

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignature }), moduleAddresses[0]);

        entryPoint.updateModule({ moduleSignature: moduleSignature, moduleAddress: moduleAddresses[1] });

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignature }), moduleAddresses[1]);

        IEntryPoint.ModuleInfo[] memory modules = entryPoint.getModules();

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleSignature, moduleSignature);
        assertEq(modules[0].moduleAddress, moduleAddresses[1]);
    }

    function test_entryPoint_updateModule_shouldRevertIfModuleNotAdded(
        bytes4 moduleSignature,
        address moduleAddress
    )
        external
    {
        assumeNotZeroAddress({ addr: moduleAddress });
        vm.assume(moduleSignature != bytes4(0));

        _resetPrank(owner);

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignature }), address(0));

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.EntryPoint_ModuleNotAdded.selector, moduleSignature));
        entryPoint.updateModule({ moduleSignature: moduleSignature, moduleAddress: moduleAddress });
    }

    function test_entryPoint_updateModule_shouldDeleteModule(
        bytes4[2] memory moduleSignatures,
        address moduleAddress
    )
        external
    {
        assumeNotZeroAddress({ addr: moduleAddress });
        vm.assume(moduleSignatures[0] != bytes4(0));
        vm.assume(moduleSignatures[1] != bytes4(0));
        vm.assume(moduleSignatures[0] != moduleSignatures[1]);

        _resetPrank(owner);

        entryPoint.addModule({ moduleSignature: moduleSignatures[0], moduleAddress: moduleAddress });
        entryPoint.addModule({ moduleSignature: moduleSignatures[1], moduleAddress: moduleAddress });

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignatures[0] }), moduleAddress);
        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignatures[1] }), moduleAddress);

        IEntryPoint.ModuleInfo[] memory modules = entryPoint.getModules();

        assertEq(modules.length, 2);
        assertEq(modules[0].moduleSignature, moduleSignatures[0]);
        assertEq(modules[0].moduleAddress, moduleAddress);
        assertEq(modules[1].moduleSignature, moduleSignatures[1]);
        assertEq(modules[1].moduleAddress, moduleAddress);

        entryPoint.updateModule({ moduleSignature: moduleSignatures[1], moduleAddress: address(0) });

        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignatures[0] }), moduleAddress);
        assertEq(entryPoint.getModuleAddress({ moduleSignature: moduleSignatures[1] }), address(0));

        modules = entryPoint.getModules();

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleSignature, moduleSignatures[0]);
        assertEq(modules[0].moduleAddress, moduleAddress);
    }

    // =========================
    // multicall
    // =========================

    function test_entryPoint_multicall_shouldCallSeveralMethodsInOneTransaction(
        uint256 value1,
        uint256 value2
    )
        external
    {
        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ to: user, give: 1000e18 });

        _resetPrank(user);
        TransferHelper.safeApprove({ token: USDT, spender: address(entryPoint), value: 1000e18 });

        EntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, address(0)),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        entryPoint.multicall{ value: 1000e18 }({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeCall(Facet1.setValue1, (value1)),
                abi.encodeCall(Facet2.setValue2, (value2)),
                abi.encodeCall(Facet2.setValue3, (value2))
            )
        });

        assertEq(Facet1(address(entryPoint)).getValue1(), value1);
        assertEq(Facet2(address(entryPoint)).getValue2(), value2);
    }

    function test_entryPoint_multicall_shouldRevertIfSelectorDoesNotExists() external {
        _resetPrank(user);

        IEntryPoint.TokenTransfers memory tokenTransfers;

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x11223344))
        );
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeWithSelector(Facet1.setValue1.selector, 1), abi.encodeWithSelector(0x11223344, 2)
            )
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x11223344))
        );
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeWithSelector(0x11223344, 1), abi.encodeWithSelector(Facet2.setValue2.selector, 2)
            )
        });
    }

    function test_entryPoint_multicall_shouldRevertIfTokensArrayNotUnique() external {
        _resetPrank(user);

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDT),
            amounts: Solarray.uint256s(1000e18, 1000e18)
        });

        vm.expectRevert(Utils.DuplicateToken.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeWithSelector(Facet1.setValue1.selector, 1))
        });
    }

    function test_entryPoint_multicall_shouldRevertIfInAmountsArrayExistsZero() external {
        deal({ token: USDT, to: user, give: 1000e18 });
        deal({ token: USDC, to: user, give: 1000e18 });

        _resetPrank(user);

        TransferHelper.safeApprove({ token: USDT, spender: address(entryPoint), value: 1000e18 });
        TransferHelper.safeApprove({ token: USDC, spender: address(entryPoint), value: 1000e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(1000e18, 0)
        });

        vm.expectRevert(Utils.UnexpectedZeroValue.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeWithSelector(Facet1.setValue1.selector, 1))
        });

        tokenTransfers = IEntryPoint.TokenTransfers({
            tokens: Solarray.addresses(USDT, USDC),
            amounts: Solarray.uint256s(0, 1000e18)
        });

        vm.expectRevert(Utils.UnexpectedZeroValue.selector);
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeWithSelector(Facet1.setValue1.selector, 1))
        });
    }

    function test_entryPoint_multicall_shouldRevertIfTokensArrayAfterAllCallsNotEmpty() external {
        deal({ token: USDT, to: user, give: 1000e18 });

        _resetPrank(user);

        TransferHelper.safeApprove({ token: USDT, spender: address(entryPoint), value: 1000e18 });

        IEntryPoint.TokenTransfers memory tokenTransfers =
            IEntryPoint.TokenTransfers({ tokens: Solarray.addresses(USDT), amounts: Solarray.uint256s(1000e18) });

        vm.expectRevert(abi.encodeWithSelector(Utils.ValuesNotEqual.selector, 1, 0));
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(abi.encodeWithSelector(Facet1.setValue1.selector, 1))
        });
    }

    function test_entryPoint_multicall_shouldRevertIfOneMethodReverts() external {
        IEntryPoint.TokenTransfers memory tokenTransfers;

        vm.expectRevert("revert method");
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeWithSelector(Facet1.revertMethod.selector), abi.encodeWithSelector(Facet1.setValue1.selector, 1)
            )
        });

        vm.expectRevert("revert method");
        entryPoint.multicall({
            tokenTransfers: tokenTransfers,
            data: Solarray.bytess(
                abi.encodeWithSelector(Facet1.setValue1.selector, 1), abi.encodeWithSelector(Facet1.revertMethod.selector)
            )
        });
    }

    // =========================
    // fallback
    // =========================

    function test_entryPoint_fallback_shouldRevertIfFacetDoesNotExists() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, InitialImplementation.upgradeTo.selector
            )
        );
        InitialImplementation(address(entryPoint)).upgradeTo({ implementation: address(0), data: bytes("") });
    }

    // =========================
    // diamond getters
    // =========================

    function test_entryPoint_facets_diamondGetters() external view {
        assertEq(entryPoint.facetAddress({ functionSelector: Facet1.setValue1.selector }), address(facet1));
        assertEq(entryPoint.facetAddress({ functionSelector: Facet2.setValue2.selector }), address(facet2));

        address[] memory _facets = entryPoint.facetAddresses();

        assertEq(_facets.length, 2);
        assertEq(_facets[0], address(facet1));
        assertEq(_facets[1], address(facet2));

        bytes4[] memory facetFunctionSelectors = entryPoint.facetFunctionSelectors({ facet: _facets[0] });
        bytes4[] memory facet1FunctionSelectorsExpected =
            Solarray.bytes4s(Facet1.setValue1.selector, Facet1.getValue1.selector, Facet1.revertMethod.selector);

        for (uint256 i; i < facetFunctionSelectors.length; ++i) {
            _assertEqual(facetFunctionSelectors[i], facet1FunctionSelectorsExpected);
        }

        facetFunctionSelectors = entryPoint.facetFunctionSelectors({ facet: _facets[1] });
        bytes4[] memory facet2FunctionSelectorsExpected = Solarray.bytes4s(
            Facet2.setValue2.selector, Facet2.getValue2.selector, Facet2.setValue3.selector, Facet2.getValue3.selector
        );

        for (uint256 i; i < facetFunctionSelectors.length; ++i) {
            _assertEqual(facetFunctionSelectors[i], facet2FunctionSelectorsExpected);
        }

        IEntryPoint.Facet[] memory facets = entryPoint.facets();

        assertEq(facets.length, 2);
        assertEq(facets[0].facet, address(facet1));
        assertEq(facets[0].functionSelectors.length, 3);
        for (uint256 i; i < facets[0].functionSelectors.length; ++i) {
            _assertEqual(facets[0].functionSelectors[i], facet1FunctionSelectorsExpected);
        }

        assertEq(facets[1].facet, address(facet2));
        assertEq(facets[1].functionSelectors.length, 4);
        for (uint256 i; i < facets[1].functionSelectors.length; ++i) {
            _assertEqual(facets[1].functionSelectors[i], facet2FunctionSelectorsExpected);
        }
    }
}
