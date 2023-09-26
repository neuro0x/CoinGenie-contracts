# SafeTransfer
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/9fabaedc72a79775729f566e1e6e755a063084c4/src/lib/SafeTransfer.sol)


## Functions
### safeTransferETH

*Sends `amount` (in wei) ETH to `to`.*


```solidity
function safeTransferETH(address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to send the ETH to.|
|`amount`|`uint256`|The amount of ETH to send.|


### validateAddress

Validates that the address is not the zero address using assembly.

*Reverts if the address is the zero address.*


```solidity
function validateAddress(address addr) internal pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`addr`|`address`|The address to validate.|


### safeTransferFrom

Helper function to transfer ERC20 tokens without the need for SafeERC20.

*Reverts if the ERC20 transfer fails.*


```solidity
function safeTransferFrom(address tokenAddress, address from, address to, uint256 amount) internal returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the ERC20 token.|
|`from`|`address`|The address to transfer the tokens from.|
|`to`|`address`|The address to transfer the tokens to.|
|`amount`|`uint256`|The amount of tokens to transfer.|


### safeTransfer

Helper function to transfer ERC20 tokens without the need for SafeERC20.

*Reverts if the ERC20 transfer fails.*


```solidity
function safeTransfer(address tokenAddress, address to, uint256 amount) internal returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the ERC20 token.|
|`to`|`address`|The address to transfer the tokens to.|
|`amount`|`uint256`|The amount of tokens to transfer.|


## Errors
### TransferFailed

```solidity
error TransferFailed();
```

