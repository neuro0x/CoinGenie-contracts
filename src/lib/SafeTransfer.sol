// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

library SafeTransfer {
    error TransferFailed();

    /**
     * @dev Sends `amount` (in wei) ETH to `to`.
     * @param to The address to send the ETH to.
     * @param amount The amount of ETH to send.
     */
    function safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                // bytes4(keccak256(bytes("ETHTransferFailed()"))) = 0xb12d13eb
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /**
     * @notice Validates that the address is not the zero address using assembly.
     * @dev Reverts if the address is the zero address.
     * @param addr The address to validate.
     */
    function validateAddress(address addr) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if iszero(shl(96, addr)) {
                // Store the function selector of `ZeroAddress()`.
                // bytes4(keccak256(bytes("ZeroAddress()"))) = 0xd92e233d
                mstore(0x00, 0xd92e233d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /**
     * @notice Helper function to transfer ERC20 tokens without the need for SafeERC20.
     * @dev Reverts if the ERC20 transfer fails.
     * @param tokenAddress The address of the ERC20 token.
     * @param from The address to transfer the tokens from.
     * @param to The address to transfer the tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransferFrom(address tokenAddress, address from, address to, uint256 amount) internal returns (bool) {
        (bool success, bytes memory data) =
        // solhint-disable-next-line avoid-low-level-calls
         tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success) {
            if (data.length != 0) {
                // bubble up error
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(data)
                    revert(add(32, data), returndata_size)
                }
            } else {
                revert TransferFailed();
            }
        }

        return true;
    }

    /// @notice Helper function to transfer ERC20 tokens without the need for SafeERC20.
    /// @dev Reverts if the ERC20 transfer fails.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to transfer.
    function safeTransfer(address tokenAddress, address to, uint256 amount) internal returns (bool) {
        (bool success, bytes memory data) =
        // solhint-disable-next-line avoid-low-level-calls
         tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success) {
            if (data.length != 0) {
                // bubble up error
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(data)
                    revert(add(32, data), returndata_size)
                }
            } else {
                revert TransferFailed();
            }
        }

        return true;
    }
}
