# ERC20Factory
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/ffc3ef50de0c400c11764979a5d358cf0ee7b768/contracts/factory/ERC20Factory.sol)

**Inherits:**
Ownable

**Author:**
@neuro_0x

*A factory library to deploy instances of the CoinGenieERC20 contract.*


## State Variables
### _genie
*The address of the genie token*


```solidity
address private _genie;
```


### _discountFeeRequiredAmount
*The amount of $GENIE a person has to hold to get the discount*


```solidity
uint256 private _discountFeeRequiredAmount = 100_000 ether;
```


## Functions
### launchToken

*Creates a new instance of the CoinGenieERC20 contract*


```solidity
function launchToken(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    address payable feeRecipient,
    address payable coinGenie,
    address payable affiliateFeeRecipient,
    uint256 taxPercent,
    uint256 deflationPercent,
    uint256 maxBuyPercent,
    uint256 maxWalletPercent
)
    external
    returns (ICoinGenieERC20 coinGenieERC20);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|- the name of the token|
|`symbol`|`string`|- the ticker symbol of the token|
|`totalSupply`|`uint256`|- the totalSupply of the token|
|`feeRecipient`|`address payable`|- the address that will be the owner of the token and receive fees|
|`coinGenie`|`address payable`|- the address of the CoinGenie contract|
|`affiliateFeeRecipient`|`address payable`|- the address to receive the affiliate fee|
|`taxPercent`|`uint256`|- the percent in basis points to use as a tax|
|`deflationPercent`|`uint256`|- the percent in basis points to use as a deflation|
|`maxBuyPercent`|`uint256`|- amount of tokens allowed to be transferred in one tx as a percent of the total supply|
|`maxWalletPercent`|`uint256`|- amount of tokens allowed to be held in one wallet as a percent of the total supply|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`coinGenieERC20`|`ICoinGenieERC20`|- the CoinGenieERC20 token that was created|


### setDiscountFeeRequiredAmount

*Allows the owner to set the amount of $GENIE a person has to hold to get the discount if it has not been set*


```solidity
function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|- the amount of $GENIE a person has to hold to get the discount|


### setGenie

*Sets the address of the genie token*


```solidity
function setGenie(address genie) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`genie`|`address`|- the address of the genie token|


## Errors
### GenieAlreadySet
Error thrown when the genie is already set.


```solidity
error GenieAlreadySet();
```

