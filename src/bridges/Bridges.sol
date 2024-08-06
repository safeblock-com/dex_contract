// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IWrappedNative } from "../interfaces/IWrappedNative.sol";
import { TransferHelper } from "../facets/libraries/TransferHelper.sol";

import { IConnext } from "./connext/IConnext.sol";

import { IStargateComposer } from "./stargate/IStargateComposer.sol";
import { IStargateFactory } from "./stargate/IStargateFactory.sol";
import { IStargatePool } from "./stargate/IStargatePool.sol";

import { ILayerZeroEndpointV2, UlnConfig } from "./layerZero/ILayerZeroEndpointV2.sol";
import { ISendLib } from "./layerZero/ISendLib.sol";

import { IAxelarGateway } from "./axelar/IAxelarGateway.sol";

import { Ownable2Step } from "../external/Ownable2Step.sol";

contract Bridges is Ownable2Step {
    using TransferHelper for address;

    address private immutable _wrappedNative;

    constructor(
        address newOwner,
        address wrappedNative,
        address connext,
        address stargateComposer,
        address layerZeroEndpoint,
        address axelarGateway
    ) {
        _wrappedNative = wrappedNative;
        _connext = IConnext(connext);
        _stargateComposer = IStargateComposer(stargateComposer);
        _layerZeroEndpoint = ILayerZeroEndpointV2(layerZeroEndpoint);
        _axelarGateway = IAxelarGateway(axelarGateway);

        // TODO to initialize
        _transferOwnership(newOwner);
        _defaultGasLimit = 35_000;
        _layerZeroEndpoint.setDelegate({ delegate: newOwner });
    }

    receive() external payable { }

    // =========================
    // events
    // =========================

    /// @notice emits when deposits confirmed
    event SentDeposits(uint256[] params, address[] to, uint256 value, uint256 fee, address from);

    // =========================
    // errors
    // =========================

    /// @notice throws when array lengths do not match
    error LengthMismatch();

    /// @notice throws when msg.value does not gte fee amount
    error FeeNotMet();

    // =========================
    // admin
    // =========================

    /// @notice withdraw any token from this contract
    /// @dev can only be called by contract owner
    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            msg.sender.safeTransferNative({ value: amount });
        } else {
            token.safeTransfer({ to: msg.sender, value: amount });
        }
    }

    // =========================
    // connext
    // =========================

    IConnext private immutable _connext;

    /**
     * @notice Transfers assets from one chain to another.
     * @dev User should approve a spending allowance before calling this.
     * @param token Address of the token on this domain.
     * @param amount The amount to transfer.
     * @param recipient The destination address (e.g. a wallet).
     * @param destinationDomain The destination domain ID.
     * @param slippage The maximum amount of slippage the user will accept in BPS.
     * @param relayerFee The fee offered to relayers.
     */
    function xTransfer(
        address token,
        uint256 amount,
        address recipient,
        uint32 destinationDomain,
        uint256 slippage,
        uint256 relayerFee
    )
        external
        payable
    {
        bytes memory callData;

        if (token == _wrappedNative) {
            // Wrap ETH into WETH to send with the xcall
            IWrappedNative(_wrappedNative).deposit{ value: amount }();
            callData = abi.encode(recipient);
        } else {
            token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });
        }

        // This contract approves transfer to Connext
        token.safeApprove({ spender: address(_connext), value: amount });

        _connext.xcall{ value: relayerFee }({
            destination: destinationDomain, // Domain ID of the destination chain
            to: recipient, // address receiving the funds on the destination
            asset: token, // address of the token contract
            delegate: msg.sender, // address that can revert or forceLocal on destination
            amount: amount, // amount of tokens to transfer
            slippage: slippage, // the maximum amount of slippage the user will accept in BPS (e.g. 30 = 0.3%)
            callData: callData
        });
    }

    // =========================
    // stargate
    // =========================

    /// @dev Address of the stargate composer for cross-chain messaging
    IStargateComposer private immutable _stargateComposer;

    function quoteFee(
        uint16 dstChainId,
        address to,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        external
        view
        returns (uint256 fee)
    {
        (fee,) = _stargateComposer.quoteLayerZeroFee({
            dstChainId: dstChainId,
            functionType: 1,
            toAddress: abi.encodePacked(to),
            transferAndCallPayload: bytes(""),
            lzTxParams: lzTxParams
        });
    }

    function sendStargateMessage(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        uint256 bridgeAmount,
        uint256 amountOutMinSg,
        address to,
        IStargateComposer.lzTxObj calldata lzTxParams
    )
        external
        payable
    {
        bytes memory _to = abi.encodePacked(to);

        (uint256 fee,) = _stargateComposer.quoteLayerZeroFee({
            dstChainId: dstChainId,
            functionType: 1,
            toAddress: _to,
            transferAndCallPayload: bytes(""),
            lzTxParams: lzTxParams
        });

        IStargatePool(IStargateFactory(_stargateComposer.factory()).getPool({ poolId: srcPoolId })).token().safeApprove({
            spender: address(_stargateComposer),
            value: bridgeAmount
        });

        _stargateComposer.swap{ value: fee }({
            dstChainId: dstChainId,
            srcPoolId: srcPoolId,
            dstPoolId: dstPoolId,
            refundAddress: payable(msg.sender),
            amountLD: bridgeAmount,
            minAmountLD: amountOutMinSg,
            lzTxParams: lzTxParams,
            to: _to,
            payload: bytes("")
        });
    }

    // =========================
    // layerZero
    // =========================

    /// @dev LayerZeroV2 endpoint
    ILayerZeroEndpointV2 internal immutable _layerZeroEndpoint;

    mapping(uint32 eid => bytes32 peer) private _peers;

    mapping(uint32 eid => uint128 gasLimit) private gasLimitLookup;

    uint128 internal _defaultGasLimit;

    // =========================

    struct EstimateFeesOptions {
        uint32 dstEid;
        bytes message;
        uint128 nativeAmount;
        address to;
    }

    function estimateFees(EstimateFeesOptions[] calldata estimateFeesOptions)
        external
        view
        returns (uint256 nativeFee)
    {
        uint256 length = estimateFeesOptions.length;

        for (uint256 i; i < length;) {
            uint32 dstEid = estimateFeesOptions[i].dstEid;
            uint128 nativeAmount = estimateFeesOptions[i].nativeAmount;

            bytes memory options;

            if (nativeAmount > 0) {
                options = _createNativeDropOption(dstEid, nativeAmount, estimateFeesOptions[i].to);
            } else {
                options = _createReceiveOption(dstEid);
            }

            unchecked {
                nativeFee += _quote(dstEid, estimateFeesOptions[i].message, options);
            }

            unchecked {
                ++i;
            }
        }
    }

    function sendDeposits(uint256[] calldata depositParams, address[] calldata to) external payable {
        uint256 length = depositParams.length;

        if (length != to.length) {
            revert LengthMismatch();
        }

        uint256 fee;
        for (uint256 i; i < length;) {
            unchecked {
                fee += _sendDeposit(uint32(depositParams[i] >> 224), uint128(depositParams[i]), to[i]);

                ++i;
            }
        }

        if (msg.value < fee) {
            revert FeeNotMet();
        }

        emit SentDeposits(depositParams, to, msg.value, fee, msg.sender);
    }

    // =========================

    /// @notice returns eid for the current chain
    function eid() external view returns (uint32) {
        return _layerZeroEndpoint.eid();
    }

    /// @notice returns default gas limit in the protocol
    function defaultGasLimit() external view returns (uint128) {
        return _defaultGasLimit;
    }

    /// @notice returns address in the bytes32 representation which refers to the passed eid
    function getPeer(uint32 dstEid) external view returns (bytes32 trustedRemote) {
        return _getPeer(dstEid);
    }

    /// @notice returns gasLimit which refers to the passed eid
    function getGasLimit(uint32 dstEid) external view returns (uint128 gasLimit) {
        gasLimit = _getGasLimit(dstEid);
    }

    /// @notice returns delegate of this contract in LayerZeroV2 endpoint
    function getDelegate() external view returns (address) {
        return _layerZeroEndpoint.delegates({ oapp: address(this) });
    }

    /// @notice returns ULN config in LayerZero protocol from passed `lib`
    function getUlnConfig(address lib, uint32 remoteEid) external view returns (UlnConfig memory) {
        bytes memory config =
            _layerZeroEndpoint.getConfig({ oapp: address(this), lib: lib, eid: remoteEid, configType: 2 });

        return abi.decode(config, (UlnConfig));
    }

    function getMessageAndNativeCap(uint32 remoteEid)
        external
        view
        returns (uint32 maxMessageSize, uint128 nativeCap)
    {
        ISendLib.ExecutorConfig memory executorConfig = ISendLib(
            _layerZeroEndpoint.getSendLibrary({ sender: address(this), dstEid: remoteEid })
        ).getExecutorConfig({ oapp: address(this), remoteEid: remoteEid });

        maxMessageSize = executorConfig.maxMessageSize;

        (,,, nativeCap) = ISendLib(executorConfig.executor).dstConfig({ dstEid: remoteEid });
    }

    function isSupportedEid(uint32 remoteEid) external view returns (bool) {
        return _layerZeroEndpoint.isSupportedEid({ eid: remoteEid });
    }

    // =========================

    /// @notice sets peers for passed remoteEids
    function setPeers(uint32[] calldata remoteEids, bytes32[] calldata remoteAddresses) external onlyOwner {
        uint256 length = remoteEids.length;
        if (length != remoteAddresses.length) {
            revert LengthMismatch();
        }

        for (uint256 i; i < length;) {
            _peers[remoteEids[i]] = remoteAddresses[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice sets gasLimit for passed remoteEids
    function setGasLimit(uint32[] calldata remoteEids, uint128[] calldata gasLimits) external onlyOwner {
        if (remoteEids.length != gasLimits.length) {
            revert LengthMismatch();
        }

        for (uint256 i; i < remoteEids.length;) {
            gasLimitLookup[remoteEids[i]] = gasLimits[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice sets new defaultGasLimit
    function setDefaultGasLimit(uint128 defaultGasLimit_) external onlyOwner {
        _defaultGasLimit = defaultGasLimit_;
    }

    /// @notice sets new delegate in LayerZeroV2 enpoint
    function setDelegate(address delegate) external onlyOwner {
        _layerZeroEndpoint.setDelegate({ delegate: delegate });
    }

    /// @notice sets ULN config for passed eids
    function setUlnConfigs(address lib, uint64 confirmations, uint32[] calldata eids, address dvn) external onlyOwner {
        uint256 length = eids.length;

        ILayerZeroEndpointV2.SetConfigParam[] memory configs = new ILayerZeroEndpointV2.SetConfigParam[](length);

        for (uint256 i; i < length; i++) {
            address[] memory opt = new address[](0);
            address[] memory req = new address[](1);
            req[0] = dvn;

            bytes memory config = abi.encode(
                UlnConfig({
                    confirmations: confirmations,
                    requiredDVNCount: uint8(1),
                    optionalDVNCount: 0,
                    optionalDVNThreshold: 0,
                    requiredDVNs: req,
                    optionalDVNs: opt
                })
            );
            configs[i] = ILayerZeroEndpointV2.SetConfigParam({ eid: eids[i], configType: 2, config: config });

            unchecked {
                ++i;
            }
        }

        _layerZeroEndpoint.setConfig({ oapp: address(this), lib: lib, params: configs });
    }

    // =========================

    /// @notice mock method for lzReceive work
    function nextNonce(uint32, bytes32) external pure virtual returns (uint64) {
        return 0;
    }

    function allowInitializePath(ILayerZeroEndpointV2.Origin calldata origin) external view virtual returns (bool) {
        return _getPeer(origin.srcEid) == origin.sender;
    }

    // =========================

    /// @dev send message with options to LayerZeroV2 endpoint
    function _lzSend(
        uint32 dstEid,
        bytes memory message,
        bytes memory options,
        uint256 nativeFee,
        address refundAddress
    )
        internal
        virtual
        returns (ILayerZeroEndpointV2.MessagingReceipt memory receipt)
    {
        return _layerZeroEndpoint.send{ value: nativeFee }({
            params: ILayerZeroEndpointV2.MessagingParams({
                dstEid: dstEid,
                receiver: _getPeer(dstEid),
                message: message,
                options: options,
                payInLzToken: false
            }),
            refundAddress: refundAddress
        });
    }

    // =========================

    /// @dev hepler method for get peer for passed dstEid
    function _getPeer(uint32 dstEid) internal view returns (bytes32 trustedRemote) {
        trustedRemote = _peers[dstEid];
        if (trustedRemote == 0) {
            assembly {
                trustedRemote := address()
            }
        }
    }

    /// @dev hepler method for get gasLimit for passed dstEid
    function _getGasLimit(uint32 dstEid) internal view returns (uint128 gasLimit) {
        gasLimit = gasLimitLookup[dstEid];
        if (gasLimit == 0) {
            gasLimit = _defaultGasLimit;
        }
    }

    /// @dev send deposit to dstEid chain
    function _sendDeposit(uint32 dstEid, uint128 amount, address to) internal returns (uint256 fee) {
        ILayerZeroEndpointV2.MessagingReceipt memory receipt =
            _lzSend(dstEid, "", _createNativeDropOption(dstEid, amount, to), address(this).balance, address(this));
        return receipt.fee.nativeFee;
    }

    /// @dev creates standard receive options
    function _createReceiveOption(uint32 dstEid) internal view returns (bytes memory) {
        return abi.encodePacked(
            // uint16(3) - type
            // uint8(1) - worker id
            // uint16(17) - payload length
            // uint8(1) - lzReceive type
            uint48(0x00301001101),
            _getGasLimit(dstEid)
        );
    }

    /// @dev creates native drop options for passed nativeAmount and `to` address
    function _createNativeDropOption(
        uint32 dstEid,
        uint128 nativeAmount,
        address to
    )
        internal
        view
        returns (bytes memory)
    {
        bytes32 _to;

        assembly {
            _to := to
        }

        return abi.encodePacked(
            _createReceiveOption(dstEid),
            // uint8(1) - worker id
            // uint16(49) - payload length
            // uint8(2) - native drop type
            uint32(0x01003102),
            nativeAmount,
            _to
        );
    }

    /// @dev calculates fee in native token for passed options
    function _quote(
        uint32 dstEid,
        bytes memory message,
        bytes memory options
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        ILayerZeroEndpointV2.MessagingFee memory fee = _layerZeroEndpoint.quote({
            params: ILayerZeroEndpointV2.MessagingParams({
                dstEid: dstEid,
                receiver: _getPeer(dstEid),
                message: message,
                options: options,
                payInLzToken: false
            }),
            sender: address(this)
        });

        return fee.nativeFee;
    }

    // =========================
    // axelar
    // =========================

    IAxelarGateway immutable _axelarGateway;

    function senTokensViaAxelar(
        string memory destinationChain,
        string memory destinationAddress,
        string memory symbol,
        uint256 amount
    )
        external
    {
        address tokenAddress = _axelarGateway.tokenAddresses(symbol);

        tokenAddress.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });

        tokenAddress.safeApprove({ spender: address(_axelarGateway), value: amount });

        _axelarGateway.sendToken({
            destinationChain: destinationChain,
            destinationAddress: destinationAddress,
            symbol: symbol,
            amount: amount
        });
    }
}
