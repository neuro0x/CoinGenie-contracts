# CoinGenieERC20
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/2b7dbfa8a0020849c0e020af4ebb51d80cd336e1/src/CoinGenieERC20.sol)

**Inherits:**
ERC20, ERC20Burnable, ERC20Pausable, Ownable, ReentrancyGuard

**Author:**
@neuro_0x

A robust and secure ERC20 token for the Coin Genie ecosystem. Inspired by APEX & TokenTool by Bitbond

THIS ERC20 SHOULD ONLY BE DEPLOYED FROM THE COINGENIE ERC20 FACTORY


## State Variables
### _MAX_BPS
Private constants

*The max basis points representing 100%*


```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### _MAX_TAX
*The max tax that can be applied to a transaction. The value is in ether but is handled as 5%.*


```solidity
uint256 private constant _MAX_TAX = 2000;
```


### _MIN_LIQUIDITY_ETH
*The minimum amount of eth that must be added to Uniswap when trading is opened.*


```solidity
uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;
```


### _MIN_LIQUIDITY_TOKEN
*The minimum amount of erc20 token that must be added to Uniswap when trading is opened.*


```solidity
uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;
```


### _TREASURY_FEE_PERCENTAGE
*the royalty fee percentage taken on transfers*


```solidity
uint256 private constant _TREASURY_FEE_PERCENTAGE = 50;
```


### _LP_ETH_FEE_PERCENTAGE
*the percent of eth taken when liquidity is open*


```solidity
uint256 private constant _LP_ETH_FEE_PERCENTAGE = 100;
```


### _AFFILIATE_FEE_PERCENTAGE
*the affiliate fee percentage taken on transfers*


```solidity
uint256 private constant _AFFILIATE_FEE_PERCENTAGE = 25;
```


### _tokenDecimals
Private immutable

*number of decimals of the token*


```solidity
uint8 private immutable _tokenDecimals;
```


### _inSwap
Private

*Are we currently swapping tokens for ETH?*


```solidity
bool private _inSwap;
```


### _feeWhitelist
*The whitelist of addresses that are exempt from fees*


```solidity
mapping(address feePayer => bool isWhitelisted) private _feeWhitelist;
```


### UNISWAP_V2_ROUTER
Public constants

*The address of the Uniswap V2 Router. The contract uses the router for liquidity provision and token swaps*


```solidity
IUniswapV2Router02 public constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### initialSupply
Public immutable

*initial number of tokens which will be minted during initialization*


```solidity
uint256 public immutable initialSupply;
```


### affiliateFeeRecipient
*address of the affiliate fee recipient*


```solidity
address public immutable affiliateFeeRecipient;
```


### genieToken
Public

*The address of the genie token*


```solidity
address public genieToken;
```


### discountFeeRequiredAmount
*The amount of $GENIE a person has to hold to get the discount*


```solidity
uint256 public discountFeeRequiredAmount;
```


### maxTokenAmountPerAddress
*max amount of tokens allowed per wallet*


```solidity
uint256 public maxTokenAmountPerAddress;
```


### tokenConfig
*features of the token*


```solidity
Common.TokenConfigProperties public tokenConfig;
```


### feeRecipient
*the address of the fee recipient*


```solidity
address public feeRecipient;
```


### treasuryRecipient
*address of the royalty fee recipient (Coin Genie)*


```solidity
address public treasuryRecipient;
```


### feePercentage
*the fee percentage in basis points*


```solidity
uint256 public feePercentage;
```


### burnPercentage
*the affiliate fee percentage in basis points*


```solidity
uint256 public burnPercentage;
```


### uniswapV2Pair
*The address of the LP token. The contract uses the LP token to determine if a transfer is a buy or sell*


```solidity
address public uniswapV2Pair;
```


### isSwapEnabled
*The flag for whether swapping is enabled and trading open*


```solidity
bool public isSwapEnabled;
```


## Functions
### lockTheSwap

Modifiers

*Modifier to prevent swapping tokens for ETH recursively*


```solidity
modifier lockTheSwap();
```

### constructor

*Initializes the contract with the provided parameters*


```solidity
constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupplyToSet,
    address tokenOwner,
    Common.TokenConfigProperties memory customConfigProps,
    uint256 maxPerWallet,
    address _affiliateFeeRecipient,
    address _feeRecipient,
    uint256 _feePercentage,
    uint256 _burnPercentage
)
    ERC20(name_, symbol_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the token|
|`symbol_`|`string`|The symbol of the token|
|`initialSupplyToSet`|`uint256`|The initial supply of the token|
|`tokenOwner`|`address`|The owner of the token|
|`customConfigProps`|`Common.TokenConfigProperties`|Represents the features of the token|
|`maxPerWallet`|`uint256`|The max amount of tokens per wallet|
|`_affiliateFeeRecipient`|`address`|The address of the affiliate fee recipient|
|`_feeRecipient`|`address`|The address of the fee recipient|
|`_feePercentage`|`uint256`|The fee percentage in basis points|
|`_burnPercentage`|`uint256`|The burn percentage in basis points|


### receive


```solidity
receive() external payable;
```

### isPausable


```solidity
function isPausable() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the token is pausable|


### isBurnable


```solidity
function isBurnable() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the token is burnable|


### isWhitelisted


```solidity
function isWhitelisted(address feePayer) public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the feePayer is whitelisted|


### decimals


```solidity
function decimals() public view virtual override returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|number of decimals for the token|


### isDeflationary


```solidity
function isDeflationary() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the token supports deflation|


### setCoinGenieTreasury

*Allows the owner to set the address of the coingenie*


```solidity
function setCoinGenieTreasury(address coinGenieAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`coinGenieAddress`|`address`|- the address of the coinGenie|


### setDiscountFeeRequiredAmount

This is called from the factory immediately after token creation

*Allows the owner to set the amount of $GENIE a person has to hold to get the discount if it has not been set*


```solidity
function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|- the amount of $GENIE a person has to hold to get the discount|


### setMaxTokenAmountPerAddress

only callable by the owner

only callable if the token is not paused

*Allows the owner to set a max amount of tokens per wallet*


```solidity
function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmount) external onlyOwner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMaxTokenAmount`|`uint256`|- the new max amount of tokens per wallet|


### setTaxConfig

only callable by the owner

only callable if the token is not paused

only callable if the feePercentage is not greater than the max tax

*Allows the owner to set the tax config*


```solidity
function setTaxConfig(address _feeRecipient, uint256 _feePercentage) external onlyOwner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeRecipient`|`address`|- the new feeRecipient|
|`_feePercentage`|`uint256`|- the new feePercentage|


### setDeflationConfig

only callable by the owner

only callable if the token is not paused

only callable if the token supports deflation

only callable if the burnPercentage is not greater than the max allowed bps

*Allows the owner to set the deflation config*


```solidity
function setDeflationConfig(uint256 _burnPercentage) external onlyOwner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_burnPercentage`|`uint256`|- the new burnPercentage|


### transfer

only callable if the token is not paused

only callable if the balance of the receiver is lower than the max amount of tokens per wallet

checks if blacklisting is enabled and if the sender and receiver are not blacklisted

checks if whitelisting is enabled and if the sender and receiver are whitelisted

captures the tax during the transfer if tax is enabvled

burns the deflationary amount during the transfer if deflation is enabled

*Allows to transfer a predefined amount of tokens to a predefined address*


```solidity
function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|- the address to transfer the tokens to|
|`amount`|`uint256`|- the amount of tokens to transfer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the transfer was successful|


### transferFrom

only callable if the token is not paused

only callable if the balance of the receiver is lower than the max amount of tokens per wallet

checks if blacklisting is enabled and if the sender and receiver are not blacklisted

checks if whitelisting is enabled and if the sender and receiver are whitelisted

captures the tax during the transfer if tax is enabvled

burns the deflationary amount during the transfer if deflation is enabled

*Allows to transfer a predefined amount of tokens from a predefined address to a predefined address*


```solidity
function transferFrom(address from, address to, uint256 amount) public virtual override whenNotPaused returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|- the address to transfer the tokens from|
|`to`|`address`|- the address to transfer the tokens to|
|`amount`|`uint256`|- the amount of tokens to transfer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the transfer was successful|


### burn

only callable by the owner

only callable if the token is not paused

only callable if the token supports burning

*Allows to burn a predefined amount of tokens*


```solidity
function burn(uint256 amount) public override onlyOwner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|- the amount of tokens to burn|


### burnFrom

only callable by the owner

only callable if the token is not paused

only callable if the token supports burning

needs Approval

*Allows to burn a predefined amount of tokens from a predefined address*


```solidity
function burnFrom(address from, uint256 amount) public override onlyOwner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|- the address to burn the tokens from|
|`amount`|`uint256`|- the amount of tokens to burn|


### pause

only callable by the owner

*Allows to pause the token*


```solidity
function pause() external onlyOwner;
```

### unpause

only callable by the owner

*Allows to unpause the token*


```solidity
function unpause() external onlyOwner;
```

### openTrading

*Opens trading for the token by adding liquidity to Uniswap.*


```solidity
function openTrading(
    uint256 amountToLP,
    bool payInGenie
)
    external
    payable
    onlyOwner
    nonReentrant
    whenNotPaused
    returns (IUniswapV2Pair);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToLP`|`uint256`|The amount of tokens to add to Uniswap|
|`payInGenie`|`bool`|Whether to pay the fee in $GENIE or ETH Emits a {TradingOpened} event. Preconditions: Requirements: `isSwapEnabled` must be false. `amountToLP >= _MIN_LIQUIDITY_TOKEN` `msg.value >= _MIN_LIQUIDITY_ETH`|


### addLiquidity

*Adds liquidity to Uniswap*


```solidity
function addLiquidity(uint256 amountToLP, bool payInGenie) external payable nonReentrant whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToLP`|`uint256`|The amount of tokens to add to Uniswap|
|`payInGenie`|`bool`|Whether to pay the fee in $GENIE or ETH|


### removeLiquidity

*Removes liquidity from Uniswap*


```solidity
function removeLiquidity(uint256 amountToRemove) external whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToRemove`|`uint256`|The amount of LP tokens to remove|


### setGenie

*Sets the address of the genie token*


```solidity
function setGenie(address genie) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`genie`|`address`|- the address of the genie token|


### _beforeTokenTransfer

*hook called before any transfer of tokens. This includes minting and burning
imposed by the ERC20 standard*


```solidity
function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
)
    internal
    virtual
    override(ERC20, ERC20Pausable);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|- address of the sender|
|`to`|`address`|- address of the recipient|
|`amount`|`uint256`|- amount of tokens to transfer|


### _takeFees


```solidity
function _takeFees(address from, address to, uint256 amount) private returns (uint256 _amount);
```

### _min

*Returns the smallest of two numbers.*


```solidity
function _min(uint256 a, uint256 b) private pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|The first number.|
|`b`|`uint256`|The second number.|


## Events
### TradingOpened
Events

This event is emitted when the trading is opened.


```solidity
event TradingOpened(address indexed pair);
```

### MaxTokensPerWalletSet
This event is emitted when the maximum number of tokens allowed per wallet has been updated.


```solidity
event MaxTokensPerWalletSet(uint256 indexed newMaxTokenAmount);
```

### FeeConfigUpdated
This event is emitted when the fee configuration of the token has been updated.


```solidity
event FeeConfigUpdated(address indexed _feeRecipient, uint256 indexed _feePercentage);
```

### BurnConfigUpdated
This event is emitted when the burn configuration of the token has been updated.


```solidity
event BurnConfigUpdated(uint256 indexed _burnPercentage);
```

## Errors
### GenieAlreadySet
Errors

Error thrown when the genie is already set.


```solidity
error GenieAlreadySet();
```

### InvalidMaxTokenAmount
Error thrown when the provided maximum token amount is invalid.


```solidity
error InvalidMaxTokenAmount(uint256 maxPerWallet);
```

### MaxTokenAmountTooHigh
Error thrown when the new maximum token amount per address is greater than the total supply.


```solidity
error MaxTokenAmountTooHigh(uint256 newAmount, uint256 maxAllowed);
```

### MaxTokenAmountTooLow
Error thrown when the new maximum token amount per address is less than 1% of the total supply.


```solidity
error MaxTokenAmountTooLow(uint256 newAmount, uint256 minAmount);
```

### DestBalanceExceedsMaxAllowed
Error thrown when the destination balance exceeds the maximum allowed amount.


```solidity
error DestBalanceExceedsMaxAllowed(address addr);
```

### BurningNotEnabled
Error thrown when burning is not enabled.


```solidity
error BurningNotEnabled();
```

### PausingNotEnabled
Error thrown when pausing is not enabled.


```solidity
error PausingNotEnabled();
```

### TokenIsNotDeflationary
Error thrown when the token is not deflationary.


```solidity
error TokenIsNotDeflationary();
```

### InvalidTaxBPS
Error thrown when an invalid tax basis point is provided.


```solidity
error InvalidTaxBPS(uint256 bps);
```

### InvalidDeflationBPS
Error thrown when an invalid deflation basis point is provided.


```solidity
error InvalidDeflationBPS(uint256 bps);
```

### TradingAlreadyOpen
Error thrown when trading is already open.


```solidity
error TradingAlreadyOpen();
```

### OnlyInitialOwner
Error thrown when the someone other than initial owner tries to manual swap tokens.


```solidity
error OnlyInitialOwner();
```

### InsufficientETH
Error thrown when the provided ETH amount is insufficient.


```solidity
error InsufficientETH(uint256 amount, uint256 minAmount);
```

### InsufficientTokens
Error thrown when the provided token amount is insufficient.


```solidity
error InsufficientTokens(uint256 amount, uint256 minAmount);
```

