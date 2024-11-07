// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { EntryPoint, IEntryPoint } from "../src/EntryPoint.sol";

import { DeployEngine } from "../script/DeployEngine.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Initializable } from "../src/proxy/Initializable.sol";

import { BaseTest } from "./BaseTest.t.sol";

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
}

contract EntryPointTest is BaseTest {
    address facet1;
    address facet2;

    function setUp() external {
        vm.createSelectFork(vm.rpcUrl("bsc"));

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

        InitialImplementation(address(entryPoint)).upgradeTo({
            implementation: entryPointImplementation,
            data: abi.encodeCall(EntryPoint.initialize, (owner, new bytes[](0)))
        });
    }

    // =========================
    // constructor and initializer
    // =========================

    event Initialized(uint8 version);

    function test_enrtryPoint_constructor_shouldDisavbleInitializers() external {
        _resetPrank(owner);

        vm.expectEmit();
        emit Initialized({ version: 255 });
        EntryPoint _entryPoint = new EntryPoint({ facetsAndSelectors: bytes("") });

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        _entryPoint.initialize({ newOwner: owner, initialCalls: new bytes[](0) });
    }

    function test_entryPoint_initialize_shouldInitializeWithNewOwnerAndCallInitialCalls() external {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = Facet1.getValue1.selector;
        selectors[1] = Facet1.setValue1.selector;
        selectors[2] = Facet2.getValue2.selector;
        selectors[3] = Facet2.setValue2.selector;
        selectors[4] = Facet2.getValue3.selector;
        selectors[5] = Facet2.setValue3.selector;

        address entryPointImplementation = address(
            new EntryPoint({
                facetsAndSelectors: DeployEngine.getBytesArray({
                    selectors: selectors,
                    addressIndexes: Solarray.uint256s(0, 0, 1, 1, 1, 1),
                    facetAddresses: Solarray.addresses(facet1, facet2)
                })
            })
        );

        InitialImplementation proxy = InitialImplementation(address(new Proxy({ initialOwner: owner })));

        _resetPrank(owner);

        vm.expectEmit();
        emit Initialized({ version: 1 });
        proxy.upgradeTo({
            implementation: entryPointImplementation,
            data: abi.encodeCall(
                EntryPoint.initialize,
                (
                    owner,
                    Solarray.bytess(
                        abi.encodeCall(Facet1.setValue1, (1)),
                        abi.encodeCall(Facet2.setValue2, (2)),
                        abi.encodeCall(Facet2.setValue3, (3))
                    )
                )
            )
        });

        assertEq(EntryPoint(payable(address(proxy))).owner(), owner);
        assertEq(Facet1(address(proxy)).getValue1(), 1);
        assertEq(Facet2(address(proxy)).getValue2(), 2);
        assertEq(Facet2(address(proxy)).getValue3(), 3);
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
            data: abi.encodeCall(EntryPoint.initialize, (owner, new bytes[](0)))
        });

        vm.expectRevert(
            abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, Facet1.setValue1.selector)
        );
        Facet1(address(proxy)).setValue1({ value: 1 });

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x000000)));
        EntryPoint(payable(address(proxy))).multicall({
            data: Solarray.bytess(abi.encodeCall(Facet1.setValue1, (1)), abi.encodeCall(Facet2.setValue2, (2)))
        });

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.EntryPoint_FunctionDoesNotExist.selector, bytes4(0x000000)));
        EntryPoint(payable(address(proxy))).multicall({
            replace: bytes32(0),
            data: Solarray.bytess(abi.encodeCall(Facet1.setValue1, (1)), abi.encodeCall(Facet2.setValue2, (2)))
        });
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
    // multicall with replace
    // =========================

    function test_entryPoint_multicallWithReplace_shouldCallSeveralMethodsInOneTx(
        uint256 value1,
        uint256 value2
    )
        external
    {
        Facet1(address(entryPoint)).setValue1({ value: value1 });
        Facet2(address(entryPoint)).setValue3({ value: value2 });

        entryPoint.multicall({
            replace: 0x0000000000000000000000000000000000000000000000000000000400000004,
            data: Solarray.bytess(
                abi.encodeCall(Facet1.getValue1, ()),
                abi.encodeCall(Facet2.setValue2, (0)),
                abi.encodeCall(Facet2.getValue3, ()),
                abi.encodeCall(Facet1.setValue1, (0))
            )
        });

        assertEq(Facet1(address(entryPoint)).getValue1(), value2);
        assertEq(Facet2(address(entryPoint)).getValue2(), value1);
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
}
