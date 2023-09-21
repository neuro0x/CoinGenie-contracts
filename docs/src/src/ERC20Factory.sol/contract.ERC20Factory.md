# ERC20Factory
[Git Source](https://github.com/neuro0x/coingenie/blob/5a9c73251afb49b9883b803681df93aa311504f5/src/ERC20Factory.sol)

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
    uint256 autoWithdrawThreshold,
    uint256 maxTaxSwap,
    address affilateFeeRecipient,
    address feeRecipient,
    uint256 feePercentage,
    uint256 burnPercentage,
    address coinGenieTreasury
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
|`autoWithdrawThreshold`|`uint256`|- the threshold at which the contract will automatically withdraw the tax fees|
|`maxTaxSwap`|`uint256`|- the maximum amount of tokens allowed to be swapped at once by manual or autoswap|
|`affilateFeeRecipient`|`address`|- the address to receive the affiliate fee|
|`feeRecipient`|`address`|- the address to receive the tax fees|
|`feePercentage`|`uint256`|- the percent in basis points to use as a tax|
|`burnPercentage`|`uint256`|- the percent in basis points to burn on every tx if this token is deflationary|
|`coinGenieTreasury`|`address`|- the address to receive the royalty fee|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newToken`|`CoinGenieERC20`|- the CoinGenieERC20 token that was created|


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

