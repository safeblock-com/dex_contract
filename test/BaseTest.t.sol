// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Solarray } from "./Solarray.sol";

import { DeployEngine, Contracts, getContracts } from "../script/DeployEngine.sol";

import { Proxy, InitialImplementation } from "../src/proxy/Proxy.sol";
import { IOwnable2Step, IOwnable } from "../src/external/IOwnable2Step.sol";
import { Ownable } from "../src/external/Ownable.sol";
import { TransferHelper } from "../src/libraries/TransferHelper.sol";
import { RouterHelper } from "../src/libraries/RouterHelper.sol";

import { Quoter } from "../src/lens/Quoter.sol";

import { EntryPoint, IEntryPoint, Initializable } from "../src/EntryPoint.sol";
import { FeeContract, IFeeContract } from "../src/FeeContract.sol";

import { Utils } from "../src/libraries/Utils.sol";

import { ISignatureTransfer } from "../src/interfaces/ISignatureTransfer.sol";

import {
    MultiswapRouterFacet, IMultiswapRouterFacet
} from "../src/facets/multiswapRouterFacet/MultiswapRouterFacet.sol";
import { TransferFacet, ITransferFacet } from "../src/facets/transferFacet/TransferFacet.sol";

import {
    StargateFacet,
    IStargateFacet,
    ILayerZeroComposer,
    OptionsBuilder,
    OFTComposeMsgCodec
} from "../src/facets/stargateFacet/StargateFacet.sol";
import { LayerZeroFacet, ILayerZeroFacet } from "../src/facets/stargateFacet/LayerZeroFacet.sol";
import { SymbiosisFacet, ISymbiosisFacet, ISymbiosis } from "../src/facets/symbiosisFacet/SymbiosisFacet.sol";
import { AcrossFacet, IAcrossFacet } from "../src/facets/acrossFacet/AcrossFacet.sol";

import { TransientStorageLibrary } from "../src/libraries/TransientStorageLibrary.sol";

import { IUniswapPool, HelperV3Lib } from "../src/lens/libraries/HelperV3Lib.sol";

import { CoinFlippersModule, ICoinFlippersModule, ICoinFlippersVault } from "../src/modules/CoinFlippersModule.sol";

import { CrossCurveFacet, ICrossCurveRouter } from "../src/facets/crossCurveFacet/CrossCurveFacet.sol";

import { console2 } from "forge-std/console2.sol";

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

    address coinFlippersModule;
    address constant coinFlippersVault = 0xA63cB21C43664B762C8401f7FFBBfc3947fF8D70;

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
            data: abi.encodeCall(IEntryPoint.initialize, (owner))
        });
        entryPoint.setFeeContractAddressAndFee({ feeContractAddress: address(feeContract), fee: 0 });

        if (block.chainid == 1) {
            coinFlippersModule = address(new CoinFlippersModule({ coinFlippersVault_: coinFlippersVault }));

            entryPoint.addModule({
                moduleSignature: ICoinFlippersModule.deposit.selector,
                moduleAddress: coinFlippersModule
            });
        }
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

    function _encodePercentageInPool(bytes32 pool, uint256 percentage) internal pure returns (bytes32 result) {
        assembly ("memory-safe") {
            result := add(shl(192, percentage), pool)
        }
    }

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    string public constant _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB =
        "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,";

    // Permit2 Witness for meta transactions
    string internal constant DATA_AND_SENDER_DETAILS_TYPE = "DataAndSenderDetails(bytes[] data,address sender)";
    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    function hash(ISignatureTransfer.PermitBatchTransferFrom memory permit) internal view returns (bytes32) {
        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                address(entryPoint),
                permit.nonce,
                permit.deadline
            )
        );
    }

    function hashWithWitness(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes32 witness
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 typeHash = keccak256(
            abi.encodePacked(
                _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB,
                abi.encodePacked(
                    "DataAndSenderDetails dataAndSenderDetails)", DATA_AND_SENDER_DETAILS_TYPE, TOKEN_PERMISSIONS_TYPE
                )
            )
        );

        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                typeHash,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                address(entryPoint),
                permit.nonce,
                permit.deadline,
                witness
            )
        );
    }

    function _hashTokenPermissions(ISignatureTransfer.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }

    function _permit2Sign(
        uint256 pk,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 deadline,
        bytes32 witness
    )
        internal
        view
        returns (bytes memory sig)
    {
        ISignatureTransfer.TokenPermissions[] memory permitted =
            new ISignatureTransfer.TokenPermissions[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            permitted[i] = ISignatureTransfer.TokenPermissions({ token: tokens[i], amount: amounts[i] });
        }

        ISignatureTransfer.PermitBatchTransferFrom memory permit =
            ISignatureTransfer.PermitBatchTransferFrom({ permitted: permitted, nonce: nonce, deadline: deadline });

        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(pk, _hashTypedData(witness > bytes32(0) ? hashWithWitness(permit, witness) : hash(permit)));

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

    function hash(bytes[] calldata data, address sender) external pure returns (bytes32) {
        return Utils.hashDataAndSenderDetails({ data: data, sender: sender });
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

    modifier checkStorage() {
        _;

        // CALLBACK
        assertEq(
            vm.load(address(entryPoint), 0x1248b983d56fa782b7a88ee11066fc0746058888ea550df970b9eea952d65dd1), bytes32(0)
        );

        // SENDER
        assertEq(
            vm.load(address(entryPoint), 0x289cc669fe96ce33e95427b15b06e5cf0e5e79eb9894ad468d456975ce05c198), bytes32(0)
        );
    }
}
