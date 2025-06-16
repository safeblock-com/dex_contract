// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISendLib {
    struct ExecutorConfig {
        uint32 maxMessageSize;
        address executor;
    }

    function getExecutorConfig(address oapp, uint32 remoteEid) external view returns (ExecutorConfig memory);

    function dstConfig(uint32 dstEid) external view returns (uint64, uint16, uint128, uint128);
}
