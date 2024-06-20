// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { Solarray } from "solarray/Solarray.sol";

import { EntryPoint } from "../src/EntryPoint.sol";

import { DeployEngine } from "../script/DeployEngine.sol";

// 0x0000000000000000000000000000000000000000000000000000000000000004
// 0xffffffff0000000000000000000000000000000000000000000000000000000000000000

// 0x1f0464d1
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000040
// 0000000000000000000000000000000000000000000000000000000000000002
// 0000000000000000000000000000000000000000000000000000000000000040
// 00000000000000000000000000000000000000000000000000000000000000a0
// 0000000000000000000000000000000000000000000000000000000000000033
// 1234567811111111111111111111111111111111111111111111111111111111
// 1111111111111111111111111111111111111100000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000004
// 9abcdef000000000000000000000000000000000000000000000000000000000

contract A {
    function a() external pure returns (uint256) {
        return 1;
    }
}

contract B {
    function b(uint256 a) external pure returns (uint256) {
        return a;
    }
}

contract Tst1 {
    function multicall(bytes32 insert, bytes[] calldata data) external {
        address[] memory facets = Solarray.addresses(address(new A()), address(new B()));

        assembly ("memory-safe") {
            for {
                let length := data.length
                let memoryOffset := add(facets, 32)
                let ptr := mload(64)

                let cDataStart := 100
                let cDataOffset := 100

                let facet

                let argOverride
            } length {
                length := sub(length, 1)
                cDataOffset := add(cDataOffset, 32)
                memoryOffset := add(memoryOffset, 32)
            } {
                facet := mload(memoryOffset)
                let offset := add(cDataStart, calldataload(cDataOffset))
                if iszero(facet) {
                    // revert EntryPoint_FunctionDoesNotExist(selector);
                    mstore(0, 0x9365f537)
                    mstore(
                        32,
                        and(
                            calldataload(add(offset, 32)),
                            0xffffffff00000000000000000000000000000000000000000000000000000000
                        )
                    )
                    revert(28, 36)
                }

                let cSize := calldataload(offset)
                calldatacopy(ptr, add(offset, 32), cSize)

                if argOverride { if returndatasize() { returndatacopy(add(ptr, argOverride), 0, returndatasize()) } }

                if iszero(delegatecall(gas(), facet, ptr, cSize, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }

                if insert {
                    argOverride := and(insert, 0xff)
                    insert := shr(insert, 8)
                }
            }
        }
    }
}

contract Tst is Test {
    EntryPoint _a;

    function setUp() external {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = A.a.selector;
        selectors[1] = B.b.selector;
        address[] memory facets = Solarray.addresses(address(new A()), address(new B()));

        _a = new EntryPoint(DeployEngine.getBytesArray(selectors, facets));
    }

    function test() external {
        _a.multicall(
            0x0000000000000000000000000000000000000000000000000000000000000004,
            Solarray.bytess(abi.encodeWithSelector(A.a.selector), abi.encodeWithSelector(B.b.selector, 0))
        );
    }
}
