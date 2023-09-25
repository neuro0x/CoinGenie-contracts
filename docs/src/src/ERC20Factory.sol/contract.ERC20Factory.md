# ERC20Factory
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/90b9fd259ed50a92a67f59cd7bd61f416f5ff1c4/src/ERC20Factory.sol)

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
uint256 private _discountFeeRequiredAmount = 1_000_000 ether;
```


## Functions
### launchToken

*Creates a new instance of the CoinGenieERC20 contract*


```solidity
function launchToken(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address tokenOwner,
    Common.TokenConfigProperties memory customConfigProps,
    uint256 maxPerWallet,
    address affiliateFeeRecipient,
    address feeRecipient,
    uint256 feePercentage,
    uint256 burnPercentage,
    address treasuryRecipient
)
    external
    returns (CoinGenieERC20 newToken);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|- the name of the token|
|`symbol`|`string`|- the ticker symbol of the token|
|`initialSupply`|`uint256`|- the initial supply of the token|
|`tokenOwner`|`address`|- the address that will be the owner of the token|
|`customConfigProps`|`Common.TokenConfigProperties`|- a struct of configuration booleans for the token|
|`maxPerWallet`|`uint256`|- the maximum amount of tokens allowed to be held by one wallet|
|`affiliateFeeRecipient`|`address`|- the address to receive the affiliate fee|
|`feeRecipient`|`address`|- the address to receive the tax fees|
|`feePercentage`|`uint256`|- the percent in basis points to use as a tax|
|`burnPercentage`|`uint256`|- the percent in basis points to burn on every tx if this token is deflationary|
|`treasuryRecipient`|`address`|- the address to receive the royalty fee|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newToken`|`CoinGenieERC20`|- the CoinGenieERC20 token that was created|


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

