# AirdropERC20
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/698fd66f744ca5be777c1f89be44bdade9f16a54/contracts/AirdropERC20.sol)

**Inherits:**
ReentrancyGuard

**Author:**
@neuro_0x

*A contract for distributing ERC20 tokens to a list of recipients.*


## State Variables
### NATIVE_TOKEN
*The address of the native token (ETH).*


```solidity
address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


## Functions
### airdrop

Allows the user to distribute ERC20 tokens to a list of addresses.

*needs Approval*


```solidity
function airdrop(
    address tokenAddress,
    address tokenOwner,
    AirdropContent[] calldata contents
)
    external
    payable
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token to be airdropped.|
|`tokenOwner`|`address`|The address of the token owner initiating the airdrop.|
|`contents`|`AirdropContent[]`|A list of recipients and amounts for the airdrop.|


### _transferCurrencyWithReturnVal

*Attempts to transfer the specified currency (either ERC20 or native) from the sender to the recipient.*


```solidity
function _transferCurrencyWithReturnVal(
    address _currency,
    address _from,
    address _to,
    uint256 _amount
)
    private
    returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_currency`|`address`|The address of the currency to be transferred.|
|`_from`|`address`|The sender's address.|
|`_to`|`address`|The recipient's address.|
|`_amount`|`uint256`|The amount to be transferred.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|A boolean indicating if the transfer was successful.|


### _safeTransferERC20

*Safely transfers ERC20 tokens from the sender to the recipient.*


```solidity
function _safeTransferERC20(address _currency, address _from, address _to, uint256 _amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_currency`|`address`|The address of the ERC20 token to be transferred.|
|`_from`|`address`|The sender's address.|
|`_to`|`address`|The recipient's address.|
|`_amount`|`uint256`|The amount to be transferred.|


## Events
### AirdropFailed
*Emitted when an failed airdrop occurs.*


```solidity
event AirdropFailed(
    address indexed tokenAddress, address indexed tokenOwner, address indexed recipient, uint256 amount
);
```

## Errors
### NoRecipients

```solidity
error NoRecipients();
```

### TokenAddressZero

```solidity
error TokenAddressZero();
```

### NotERC20

```solidity
error NotERC20();
```

### InsufficientBalance

```solidity
error InsufficientBalance();
```

### InsufficientAllowance

```solidity
error InsufficientAllowance();
```

## Structs
### AirdropContent
*Details of amount and recipient for airdropped token.*


```solidity
struct AirdropContent {
    address recipient;
    uint256 amount;
}
```

