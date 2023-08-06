// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HelperLib {
    uint256 constant E4 = 1e4;
    error TransferFromFailed();
    error TransferFailed();
    error UniswapV2_InsufficientInputAmount();
    error UniswapV2_InsufficientOutputAmount();
    error UniswapV2_InsufficientLiquidity();

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE4
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            revert UniswapV2_InsufficientInputAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            revert UniswapV2_InsufficientLiquidity();
        }

        unchecked {
            uint256 amountInWithFee = amountIn * (feeE4);
            uint256 numerator = amountInWithFee * (reserveOut);
            uint256 denominator = reserveIn * E4 + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeE4
    ) internal pure returns (uint256 amountIn) {
        if (amountIn == 0) {
            revert UniswapV2_InsufficientOutputAmount();
        }
        if (reserveIn == 0 || reserveOut == 0) {
            revert UniswapV2_InsufficientLiquidity();
        }

        unchecked {
            uint256 numerator = reserveIn * amountOut * E4;
            uint256 denominator = reserveOut - amountOut * feeE4;
            amountIn = (numerator / denominator) + 1;
        }
    }

    // https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol#L65
    function safeTransfer(address token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) {
            revert TransferFailed();
        }
    }

    // https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol#L31
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) {
            revert TransferFromFailed();
        }
    }
}
