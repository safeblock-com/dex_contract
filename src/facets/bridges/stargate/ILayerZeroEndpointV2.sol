// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct UlnConfig {
    uint64 confirmations;
    // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
    uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNThreshold; // (0, optionalDVNCount]
    address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
    address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
}

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
    bool payInLzToken;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

interface ILayerZeroEndpointV2 {
    function quote(MessagingParams calldata params, address sender) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata params,
        address refundAddress
    )
        external
        payable
        returns (MessagingReceipt memory);

    function lzReceive(
        Origin calldata origin,
        address receiver,
        bytes32 guid,
        bytes calldata message,
        bytes calldata extraData
    )
        external
        payable;

    function nativeToken() external view returns (address);

    function setDelegate(address delegate) external;

    function delegates(address oapp) external view returns (address);

    function getConfig(
        address oapp,
        address lib,
        uint32 eid,
        uint32 configType
    )
        external
        view
        returns (bytes memory config);

    function getSendLibrary(address sender, uint32 dstEid) external view returns (address lib);

    function eid() external view returns (uint32);

    function isSupportedEid(uint32 eid) external view returns (bool);
}
