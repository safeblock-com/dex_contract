// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMessageLibManager {
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }

    /// ------------------- OApp interfaces -------------------

    function isDefaultSendLibrary(address sender, uint32 eid) external view returns (bool);

    function setConfig(address oapp, address lib, SetConfigParam[] calldata params) external;

    function getConfig(
        address oapp,
        address lib,
        uint32 eid,
        uint32 configType
    )
        external
        view
        returns (bytes memory config);
}
