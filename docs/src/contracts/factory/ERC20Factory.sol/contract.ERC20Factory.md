# ERC20Factory
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/05843ace75c27defbf1e70d42b8feb05c0e88219/contracts/factory/ERC20Factory.sol)

**Inherits:**
Ownable, ReentrancyGuard

**Author:**
@neuro_0x

*A factory library to deploy instances of the CoinGenieERC20 contract.*


## State Variables
### _genie
*The address of the genie token*


```solidity
address private _genie;
```


### _coinGenie
*The address of the coin genie*


```solidity
address payable private _coinGenie;
```


### _discountFeeRequiredAmount
*The amount of $GENIE a person has to hold to get the discount*


```solidity
uint256 private _discountFeeRequiredAmount = 100_000 ether;
```


## Functions
### genie


```solidity
function genie() public view returns (address);
```

### coinGenie


```solidity
function coinGenie() public view returns (address);
```

### launchToken

*Creates a new instance of the CoinGenieERC20 contract*


```solidity
function launchToken(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    address payable feeRecipient,
    address payable affiliateFeeRecipient,
    uint256 taxPercent,
    uint256 maxBuyPercent,
    uint256 maxWalletPercent
)
    external
    nonReentrant
    returns (ICoinGenieERC20 coinGenieERC20);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|- the name of the token|
|`symbol`|`string`|- the ticker symbol of the token|
|`totalSupply`|`uint256`|- the totalSupply of the token|
|`feeRecipient`|`address payable`|- the address that will be the owner of the token and receive fees|
|`affiliateFeeRecipient`|`address payable`|- the address to receive the affiliate fee|
|`taxPercent`|`uint256`|- the percent in basis points to use as a tax|
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
function setGenie(address genie_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`genie_`|`address`|- the address of the genie token|


### setCoinGenie

*Sets the address of the coin genie*


```solidity
function setCoinGenie(address payable coinGenie_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`coinGenie_`|`address payable`|- the address of the coin genie|


## Events
### GenieSet

```solidity
event GenieSet(address indexed genieAddress);
```

### CoinGenieSet

```solidity
event CoinGenieSet(address indexed coinGenieAddress);
```

### DiscountFeeRequiredAmountSet

```solidity
event DiscountFeeRequiredAmountSet(uint256 indexed amount);
```

## Errors
### GenieAlreadySet

```solidity
error GenieAlreadySet(address genieAddress);
```

### CoinGenieAlreadySet

```solidity
error CoinGenieAlreadySet(address coinGenieAddress);
```

