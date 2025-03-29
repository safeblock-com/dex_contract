// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "./Solarray.sol";

import { DeployEngine, Contracts, getContracts } from "../script/DeployEngine.sol";

import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { IOwnable2Step, IOwnable } from "../src/external/IOwnable2Step.sol";
import { Ownable } from "../src/external/Ownable.sol";
import { TransferHelper } from "../src/facets/libraries/TransferHelper.sol";

import { Quoter } from "../src/lens/Quoter.sol";

import { EntryPoint, IEntryPoint, Initializable } from "../src/EntryPoint.sol";
import { FeeContract, IFeeContract } from "../src/FeeContract.sol";

import { MultiswapRouterFacet, IMultiswapRouterFacet } from "../src/facets/MultiswapRouterFacet.sol";
import { TransferFacet, ITransferFacet, ISignatureTransfer } from "../src/facets/TransferFacet.sol";

import {
    StargateFacet,
    IStargateFacet,
    ILayerZeroComposer,
    OptionsBuilder,
    OFTComposeMsgCodec
} from "../src/facets/bridges/StargateFacet.sol";
import { LayerZeroFacet, ILayerZeroFacet } from "../src/facets/bridges/LayerZeroFacet.sol";
import { SymbiosisFacet, ISymbiosisFacet, ISymbiosis } from "../src/facets/bridges/SymbiosisFacet.sol";

import { TransientStorageFacetLibrary } from "../src/libraries/TransientStorageFacetLibrary.sol";

import { EfficientSwapAmount, IUniswapPool, HelperV3Lib } from "../src/lens/libraries/EfficientSwapAmount.sol";

import { console } from "forge-std/console.sol";

contract BaseTest is Test {
    address owner;
    uint256 ownerPk;
    address user;
    uint256 userPk;

    EntryPoint entryPoint;
    Quoter quoter;
    FeeContract feeContract;

    Contracts contracts;

    ISignatureTransfer _permit2;

    function deployForTest() internal {
        contracts = getContracts({ chainId: block.chainid });

        _permit2 = ISignatureTransfer(contracts.permit2);

        (contracts,) = DeployEngine.deployImplementations({ contracts: contracts, isTest: true });

        quoter = Quoter(address(new Proxy({ initialOwner: owner })));
        InitialImplementation(address(quoter)).upgradeTo({
            implementation: address(new Quoter({ wrappedNative_: contracts.wrappedNative })),
            data: abi.encodeCall(Quoter.initialize, (owner))
        });

        entryPoint = EntryPoint(payable(address(new Proxy({ initialOwner: owner }))));
        feeContract = FeeContract(payable(address(new Proxy({ initialOwner: owner }))));

        InitialImplementation(address(feeContract)).upgradeTo({
            implementation: address(new FeeContract()),
            data: abi.encodeCall(FeeContract.initialize, (owner, address(entryPoint)))
        });

        InitialImplementation(address(entryPoint)).upgradeTo({
            implementation: DeployEngine.deployEntryPoint({ contracts: contracts }),
            data: abi.encodeCall(IEntryPoint.initialize, (owner, new bytes[](0)))
        });
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 0 });
    }

    // helper

    function _createUsers() internal {
        (owner, ownerPk) = makeAddrAndKey({ name: "owner" });
        (user, userPk) = makeAddrAndKey({ name: "user" });
    }

    function _resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }

    function _resetPrank(address msgSender, address origin) internal {
        vm.stopPrank();
        vm.startPrank(msgSender, origin);
    }

    function _expectERC20TransferCall(address token, address to, uint256 amount) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.transfer, (to, amount)));
    }

    function _expectERC20ApproveCall(address token, address to, uint256 amount) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.approve, (to, amount)));
    }

    function _expectERC20TransferFromCall(address token, address from, address to, uint256 amount) internal {
        vm.expectCall(token, abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
    }

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    function _permit2Sign(
        uint256 pk,
        ISignatureTransfer.PermitTransferFrom memory permit
    )
        internal
        view
        returns (bytes memory sig)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            pk,
            _hashTypedData(
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH,
                        keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted)),
                        address(entryPoint),
                        permit.nonce,
                        permit.deadline
                    )
                )
            )
        );

        sig = new bytes(64);
        assembly ("memory-safe") {
            mstore(add(sig, 32), r)
            mstore(add(sig, 64), or(shl(255, eq(v, 28)), s))
        }
    }

    function _hashTypedData(bytes32 dataHash) internal view returns (bytes32) {
        address permit2 = contracts.permit2;
        bytes32 domainSeparator;
        assembly ("memory-safe") {
            // DOMAIN_SEPARATOR() selector
            mstore(0, 0x3644e515)
            pop(staticcall(gas(), permit2, 28, 4, 0, 32))
            domainSeparator := mload(0)
        }

        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, dataHash));
    }

    function _assertEqual(bytes4 selector, bytes4[] memory selectors) internal pure {
        bool contains;

        for (uint256 i; i < selectors.length; ++i) {
            if (selectors[i] == selector) {
                contains = true;
                break;
            }
        }

        assertTrue(contains);
    }

    modifier checkTokenStorage(address[] memory tokens) {
        _;

        // CALLBACK
        assertEq(
            vm.load(address(entryPoint), 0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd1), bytes32(0)
        );

        for (uint256 i; i < tokens.length; ++i) {
            assertEq(vm.load(address(entryPoint), bytes32(uint256(uint160(tokens[i])))), bytes32(0));
        }

        // SENDER
        assertEq(
            vm.load(address(entryPoint), 0x289cc669fe96ce33e95427b15b06e5cf0e5e79eb9894ad468d456975ce05c198), bytes32(0)
        );

        assertEq(
            vm.load(address(entryPoint), 0xc0abc52de3d4e570867f700eb5dfe2c039750b7f48720ee0d6152f3aa8676374), bytes32(0)
        );
    }
}
