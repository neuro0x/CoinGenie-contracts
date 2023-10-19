# ICoinGenieERC20
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/e0a4bc3965fb3bf295a77ef5df6f448c83ec3a3f/contracts/token/ICoinGenieERC20.sol)

**Inherits:**
IERC20

**Author:**
@neuro_0x

*Interface for the CoinGenie ERC20 token*


## Functions
### name

*Gets the name of the token*


```solidity
function name() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|the name of the token|


### symbol

*Gets the symbol of the token*


```solidity
function symbol() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|the symbol of the token|


### decimals

*Gets the number of decimals the token uses*


```solidity
function decimals() external pure returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|the number of decimals the token uses|


### totalSupply

*Gets the total supply of the token*


```solidity
function totalSupply() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total supply of the token|


### feeRecipient

*Gets the address of the fee recipient*


```solidity
function feeRecipient() external view returns (address payable);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address payable`|the address of the fee recipient|


### coinGenie

*Gets the address of the CoinGenie contract*


```solidity
function coinGenie() external view returns (address payable);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address payable`|the address of the CoinGenie contract|


### genie

*Gets the address of the $GENIE contract*


```solidity
function genie() external view returns (address payable);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address payable`|the address of the $GENIE contract|


### affiliateFeeRecipient

*Gets the address of the affiliate fee recipient*


```solidity
function affiliateFeeRecipient() external view returns (address payable);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address payable`|the address of the affiliate fee recipient|


### isTradingOpen

*Gets the trading status of the token*


```solidity
function isTradingOpen() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|the trading status of the token|


### isSwapEnabled

*Gets the trading status of the token*


```solidity
function isSwapEnabled() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|the trading status of the token|


### taxPercent

*Gets the tax percent*


```solidity
function taxPercent() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the tax percent|


### maxBuyPercent

*Gets the max buy percent*


```solidity
function maxBuyPercent() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the max buy percent|


### maxWalletPercent

*Gets the max wallet percent*


```solidity
function maxWalletPercent() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the max wallet percent|


### discountFeeRequiredAmount

*Gets the discount fee required amount in $GENIE*


```solidity
function discountFeeRequiredAmount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the discount fee required amount in $GENIE|


### discountPercent

*Gets the discount percent received if paying in $GENIE*


```solidity
function discountPercent() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the discount percent received if paying in $GENIE|


### lpToken

*Gets the Uniswap V2 pair address*


```solidity
function lpToken() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|the uniswap v2 pair address|


### balanceOf

*Gets the balance of the specified address*


```solidity
function balanceOf(address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|- the address to get the balance of|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the balance of the account|


### amountEthReceived

*Gets the amount of eth received by the fee recipient*


```solidity
function amountEthReceived(address feeRecipient_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient_`|`address`|- the address to get the amount of eth received|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of eth received|


### burn

*Burns `amount` tokens from the caller*


```solidity
function burn(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|- the amount of tokens to burn|


### transfer

*Transfers `amount` tokens to `recipient`*


```solidity
function transfer(address recipient, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|- the address to transfer to|
|`amount`|`uint256`|- the amount of tokens to transfer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the transfer was successful|


### allowance

*Gets the allowance of an address to spend tokens on behalf of the owner*


```solidity
function allowance(address owner, address spender) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|- the address to get the allowance of|
|`spender`|`address`|- the address to get the allowance for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the allowance of the owner for the spender|


### approve

*Approves an address to spend tokens on behalf of the caller*


```solidity
function approve(address spender, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`spender`|`address`|- the address to approve|
|`amount`|`uint256`|- the amount to approve|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the approval was successful|


### transferFrom

*Transfers tokens from one address to another*


```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|- the address to transfer from|
|`recipient`|`address`|- the address to transfer to|
|`amount`|`uint256`|- the amount to transfer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the transfer was successful|


### manualSwap

*Swaps the contracts tokens for eth*


```solidity
function manualSwap(uint256 amount) external;
```

### createPairAndAddLiquidity

*Opens trading by adding liquidity to Uniswap V2*


```solidity
function createPairAndAddLiquidity(uint256 amountToLP, bool payInGenie) external payable returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToLP`|`uint256`|- the amount of tokens to add liquidity with|
|`payInGenie`|`bool`|- true if paying with $GENIE|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|the address of the LP Token created|


### addLiquidity

*Adds liquidity to Uniswap V2*


```solidity
function addLiquidity(uint256 amountToLP, bool payInGenie) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToLP`|`uint256`|- the amount of tokens to add liquidity with|
|`payInGenie`|`bool`|- true if paying with $GENIE|


### removeLiquidity

*Removes liquidity from Uniswap V2*


```solidity
function removeLiquidity(uint256 amountToRemove) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToRemove`|`uint256`|- the amount of LP tokens to remove|


### setGenie

*Sets the address of the $GENIE contract*


```solidity
function setGenie(address genie_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`genie_`|`address`|- the address of the $GENIE contract|


### setFeeRecipient

*Sets the fee recipient*


```solidity
function setFeeRecipient(address payable feeRecipient_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient_`|`address payable`|- the address of the fee recipient|


### setMaxBuyPercent

*Sets the max amount of tokens that can be bought in a tx as a percent of the total supply*


```solidity
function setMaxBuyPercent(uint256 maxBuyPercent_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxBuyPercent_`|`uint256`|- the max buy percent|


### setMaxWalletPercent

*Sets the max amount of tokens a wallet can hold as a percent of the total supply*


```solidity
function setMaxWalletPercent(uint256 maxWalletPercent_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxWalletPercent_`|`uint256`|- the max wallet percent|


### setCoinGenieFeePercent

Sets the Coin Genie fee percentage.


```solidity
function setCoinGenieFeePercent(uint256 coinGenieFeePercent_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`coinGenieFeePercent_`|`uint256`|The Coin Genie fee percentage.|


## Events
### GenieSet
*Emits when Genie is set*


```solidity
event GenieSet(address indexed genie);
```

### TradingOpened
*Emits when trading is opened*


```solidity
event TradingOpened(address indexed pair);
```

### MaxBuyPercentSet
*Emits when the max buy percent is set*


```solidity
event MaxBuyPercentSet(uint256 indexed maxBuyPercent);
```

### FeeRecipientSet
*Emits when the fee recipient is set*


```solidity
event FeeRecipientSet(address indexed feeRecipient);
```

### MaxWalletPercentSet
*Emits when the max wallet percent is set*


```solidity
event MaxWalletPercentSet(uint256 indexed maxWalletPercent);
```

### EthSentToFee
*Emits when eth is sent to the fee recipients*


```solidity
event EthSentToFee(uint256 indexed feeRecipientShare, uint256 indexed coinGenieShare);
```

## Errors
### Unauthorized
*Reverts when the caller is not authorized to perform an action*


```solidity
error Unauthorized();
```

### TradingNotOpen
*Reverts when trading is not open*


```solidity
error TradingNotOpen();
```

### GenieAlreadySet
*Reverts when Genie is already set*


```solidity
error GenieAlreadySet();
```

### TradingAlreadyOpen
*Reverts when trading is already open*


```solidity
error TradingAlreadyOpen();
```

### BurnFromZeroAddress
*Reverts when trying to burn from the zero address*


```solidity
error BurnFromZeroAddress();
```

### ApproveFromZeroAddress
*Reverts when trying to approve from the zero address*


```solidity
error ApproveFromZeroAddress();
```

### TransferFromZeroAddress
*Reverts when trying to transfer from the zero address*


```solidity
error TransferFromZeroAddress();
```

### CoinGenieFeePercentAlreadySet
*Reverts when coin genie fee is already set*


```solidity
error CoinGenieFeePercentAlreadySet();
```

### InvalidCoinGenieFeePercent
*Reverts when invalid coin genie fee percent*


```solidity
error InvalidCoinGenieFeePercent();
```

### InvalidTotalSupply
*Reverts when invalid total supply*


```solidity
error InvalidTotalSupply(uint256 totalSupply);
```

### InvalidMaxWalletPercent
*Reverts when trying to set an invalid max wallet percent*


```solidity
error InvalidMaxWalletPercent(uint256 maxWalletPercent);
```

### InvalidMaxBuyPercent
*Reverts when trying to set an invalid max buy percent*


```solidity
error InvalidMaxBuyPercent(uint256 maxBuyPercent);
```

### InsufficientETH
*Reverts when there is not enough eth send in the tx*


```solidity
error InsufficientETH(uint256 amount, uint256 minAmount);
```

### ExceedsMaxAmount
*Reverts when the amount sent is beyond the max amount allowed*


```solidity
error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);
```

### InsufficientTokens
*Reverts when there are not enough tokens to perform the action*


```solidity
error InsufficientTokens(uint256 amount, uint256 minAmount);
```

### InsufficientAllowance
*Reverts when there is not enough allowance to perform the action*


```solidity
error InsufficientAllowance(uint256 amount, uint256 allowance);
```

### TransferFailed
*Reverts when there is an error when transferring*


```solidity
error TransferFailed(uint256 amount, address from, address to);
```

