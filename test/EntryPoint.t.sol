// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { EntryPoint, IEntryPoint } from "../src/EntryPoint.sol";

import { DeployEngine } from "../script/DeployEngine.sol";

import { Initializable } from "../src/proxy/Initializable.sol";

import { BaseTest, Solarray, FeeContract } from "./BaseTest.t.sol";

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

    function setValue1(uint256 value) external {
        _getLocalStorage().value = value;
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

    function setValue2(uint256 value) external {
        _getLocalStorage().value = value;
    }

    function getValue3() external view returns (uint256) {
        return _getLocalStorage().value2;
    }

    function setValue3(uint256 value) external {
        _getLocalStorage().value2 = value;
    }

    function moduleMethod1() external pure { }
}

contract EntryPointTest is BaseTest {
    address facet1;
    address facet2;

    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc_public"));

        _createUsers();

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
                })
            })
        );

        entryPoint = EntryPoint(payable(address(new Proxy({ initialOwner: owner }))));

        feeContract = FeeContract(payable(makeAddr("feeContract")));

        InitialImplementation(address(entryPoint)).upgradeTo({
            implementation: entryPointImplementation,
            data: abi.encodeCall(EntryPoint.initialize, (owner))
        });
    }

    // =========================
    // constructor and initializer
    // =========================

    event Initialized(uint8 version);

    function test_entryPoint_constructor_shouldDisavbleInitializers() external {
        _resetPrank(owner);

        vm.expectEmit();
        emit Initialized({ version: 255 });
        EntryPoint _entryPoint = new EntryPoint({ facetsAndSelectors: bytes("") });

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _entryPoint.initialize({ newOwner: owner });
    }

    // =========================
    // empty facets and selectors
    // =========================

    function test_entryPoint_shouldRevertIfNoFacetsAndSelectors() external {
        address entryPointImplementation = address(new EntryPoint({ facetsAndSelectors: bytes("") }));

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

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x000000)));
        EntryPoint(payable(address(proxy))).multicall({
            data: Solarray.bytess(abi.encodeCall(Facet1.setValue1, (1)), abi.encodeCall(Facet2.setValue2, (2)))
        });
    }

    // =========================
    // setFeeContractAddress
    // =========================

    function test_entryPoint_setFeeContractAddress_shouldSetFeeContractAddress() external {
        (address feeContract, uint256 fee) = entryPoint.getFeeContractAddressAndFee();
        assertEq(feeContract, address(0));
        assertEq(fee, 0);

        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 300 });

        (feeContract, fee) = entryPoint.getFeeContractAddressAndFee();
        assertEq(feeContract, address(feeContract));
        assertEq(fee, 300);
    }

    // =========================
    // multicall
    // =========================

    function test_entryPoint_multicall_shouldCallSeveralMethodsInOneTx(uint256 value1, uint256 value2) external {
        entryPoint.multicall({
            data: Solarray.bytess(abi.encodeCall(Facet1.setValue1, (value1)), abi.encodeCall(Facet2.setValue2, (value2)))
        });

        assertEq(Facet1(address(entryPoint)).getValue1(), value1);
        assertEq(Facet2(address(entryPoint)).getValue2(), value2);
    }

    function test_entryPoint_multicall_shouldRevertIfSelectorDoesNotExists() external {
        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x11223344))
        );
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeWithSelector(Facet1.setValue1.selector, 1), abi.encodeWithSelector(0x11223344, 2)
            )
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x11223344))
        );
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeWithSelector(0x11223344, 1), abi.encodeWithSelector(Facet2.setValue2.selector, 2)
            )
        });
    }

    function test_entryPoint_multicall_shouldRevertIfOneMethodReverts() external {
        vm.expectRevert("revert method");
        entryPoint.multicall({
            data: Solarray.bytess(
                abi.encodeWithSelector(Facet1.revertMethod.selector), abi.encodeWithSelector(Facet1.setValue1.selector, 1)
            )
        });

        vm.expectRevert("revert method");
        entryPoint.multicall({
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

    // =========================
    // modules
    // =========================

    function test_entryPoint_modules_shouldAddModule() external {
        _resetPrank(owner);

        assertEq(entryPoint.getModuleAddress(Facet1.moduleMethod1.selector), address(0));

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, Facet1.moduleMethod1.selector)
        );
        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(Facet1.moduleMethod1, ())) });

        entryPoint.addModule({ moduleSignature: Facet1.moduleMethod1.selector, moduleAddress: address(facet1) });

        assertEq(entryPoint.getModuleAddress(Facet1.moduleMethod1.selector), address(facet1));

        IEntryPoint.ModuleInfo[] memory modules = entryPoint.getModules();

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleSignature, Facet1.moduleMethod1.selector);
        assertEq(modules[0].moduleAddress, address(facet1));

        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(Facet1.moduleMethod1, ())) });

        entryPoint.addModule({ moduleSignature: Facet1.moduleMethod2.selector, moduleAddress: address(facet1) });

        entryPoint.multicall({
            data: Solarray.bytess(abi.encodeCall(Facet1.moduleMethod1, ()), abi.encodeCall(Facet1.moduleMethod2, ()))
        });

        modules = entryPoint.getModules();

        assertEq(modules.length, 2);
        assertEq(modules[1].moduleSignature, Facet1.moduleMethod2.selector);
        assertEq(modules[1].moduleAddress, address(facet1));

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_ModuleAlreadyAdded.selector, Facet1.moduleMethod1.selector)
        );
        entryPoint.addModule({ moduleSignature: Facet2.moduleMethod1.selector, moduleAddress: address(facet2) });
    }

    function test_entryPoint_modules_shouldUpdateOrDeleteModule() external {
        _resetPrank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_ModuleNotAdded.selector, Facet1.moduleMethod2.selector)
        );
        entryPoint.updateModule({ moduleSignature: Facet1.moduleMethod2.selector, moduleAddress: address(facet1) });

        entryPoint.addModule({ moduleSignature: Facet1.moduleMethod2.selector, moduleAddress: address(facet1) });
        entryPoint.addModule({ moduleSignature: Facet1.moduleMethod1.selector, moduleAddress: address(facet1) });

        IEntryPoint.ModuleInfo[] memory modules = entryPoint.getModules();

        assertEq(modules.length, 2);
        assertEq(modules[0].moduleSignature, Facet1.moduleMethod2.selector);
        assertEq(modules[0].moduleAddress, address(facet1));
        assertEq(modules[1].moduleSignature, Facet1.moduleMethod1.selector);
        assertEq(modules[1].moduleAddress, address(facet1));

        entryPoint.multicall({ data: Solarray.bytess(abi.encodeCall(Facet1.moduleMethod1, ())) });

        entryPoint.updateModule({ moduleSignature: Facet2.moduleMethod1.selector, moduleAddress: address(facet2) });

        assertEq(entryPoint.getModuleAddress(Facet2.moduleMethod1.selector), address(facet2));

        modules = entryPoint.getModules();

        assertEq(modules.length, 2);
        assertEq(modules[0].moduleSignature, Facet1.moduleMethod2.selector);
        assertEq(modules[0].moduleAddress, address(facet1));
        assertEq(modules[1].moduleSignature, Facet2.moduleMethod1.selector);
        assertEq(modules[1].moduleAddress, address(facet2));

        entryPoint.updateModule({ moduleSignature: Facet1.moduleMethod2.selector, moduleAddress: address(0) });

        assertEq(entryPoint.getModuleAddress(Facet1.moduleMethod2.selector), address(0));

        modules = entryPoint.getModules();

        assertEq(modules.length, 1);
        assertEq(modules[0].moduleSignature, Facet1.moduleMethod1.selector);
        assertEq(modules[0].moduleAddress, address(facet2));
    }
}
