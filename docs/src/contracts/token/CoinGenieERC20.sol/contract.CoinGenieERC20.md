# CoinGenieERC20
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/bb01504e3d629c383b1d91931fcf1abe87915011/contracts/token/CoinGenieERC20.sol)

**Inherits:**
[ICoinGenieERC20](/contracts/token/ICoinGenieERC20.sol/interface.ICoinGenieERC20.md), Ownable, ReentrancyGuard

**Author:**
@neuro_0x

A robust and secure ERC20 token for the Coin Genie ecosystem. Inspired by APEX & TokenTool by Bitbond

*This ERC20 should only be deployed via the launchToken function of the CoinGenie contract.*


## State Variables
### _DECIMALS
*The decimals for the contract*


```solidity
uint8 private constant _DECIMALS = 18;
```


### _MAX_BPS
*The max basis points*


```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### _MAX_TAX
*The max tax that can be set*


```solidity
uint256 private constant _MAX_TAX = 500;
```


### _MIN_LIQUIDITY_ETH
*The min amount of eth required to open trading*


```solidity
uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;
```


### _MIN_LIQUIDITY_TOKEN
*The min amount of this token required to open trading*


```solidity
uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;
```


### _LP_ETH_FEE_PERCENTAGE
*The platform liquidity addition fee*


```solidity
uint256 private constant _LP_ETH_FEE_PERCENTAGE = 100;
```


### _MIN_WALLET_PERCENT
*The platform liquidity addition fee*


```solidity
uint256 private constant _MIN_WALLET_PERCENT = 100;
```


### _ETH_AUTOSWAP_AMOUNT
*The eth autoswap amount*


```solidity
uint256 private constant _ETH_AUTOSWAP_AMOUNT = 0.025 ether;
```


### _UNISWAP_V2_ROUTER
*The address of the Uniswap V2 Router*


```solidity
IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _balances
*Mapping of holders and their balances*


```solidity
mapping(address holder => uint256 balance) private _balances;
```


### _allowances
*Mapping of holders and their allowances*


```solidity
mapping(address holder => mapping(address spender => uint256 allowance)) private _allowances;
```


### _whitelist
*Mapping of holders and their whitelist status*


```solidity
mapping(address holder => bool isWhiteListed) private _whitelist;
```


### _ethReceived
*Mapping of fee recipients and the amount of eth they have received*


```solidity
mapping(address feeRecipient => uint256 amountEthReceived) private _ethReceived;
```


### _feeTakers
*The fee recipients for the contract*


```solidity
FeeTakers private _feeTakers;
```


### _feeAmounts
*The fee percentages for the contract*


```solidity
FeePercentages private _feeAmounts;
```


### _genie
*The $GENIE contract*


```solidity
CoinGenieERC20 private _genie;
```


### _uniswapV2Pair
*The address of the Uniswap V2 Pair*


```solidity
address private _uniswapV2Pair;
```


### _isFeeSet
*The coin genie fee is set*


```solidity
bool private _isFeeSet;
```


### _isTradingOpen
*The trading status of the contract*


```solidity
bool private _isTradingOpen;
```


### _inSwap
*The current swap status of the contract, used for reentrancy checks*


```solidity
bool private _inSwap;
```


### _isSwapEnabled
*The swap status of the contract*


```solidity
bool private _isSwapEnabled;
```


### _name
*The name of the token*


```solidity
string private _name;
```


### _symbol
*The symbol of the token*


```solidity
string private _symbol;
```


### _totalSupply
*The total supply of the token*


```solidity
uint256 private _totalSupply;
```


## Functions
### lockTheSwap

*Prevents a reentrant call when trying to swap fees*


```solidity
modifier lockTheSwap();
```

### constructor


```solidity
constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address payable feeRecipient_,
    address payable coinGenie_,
    address payable affiliateFeeRecipient_,
    uint256 taxPercent_,
    uint256 maxBuyPercent_,
    uint256 maxWalletPercent_,
    uint256 discountFeeRequiredAmount_,
    uint256 discountPercent_
)
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|- the name of the token|
|`symbol_`|`string`|- the ticker symbol of the token|
|`totalSupply_`|`uint256`|- the totalSupply of the token|
|`feeRecipient_`|`address payable`|- the address that will be the owner of the token and receive fees|
|`coinGenie_`|`address payable`|- the address of the Coin Genie|
|`affiliateFeeRecipient_`|`address payable`|- the address to receive the affiliate fee|
|`taxPercent_`|`uint256`|- the percent in basis points to use as a tax|
|`maxBuyPercent_`|`uint256`|- amount of tokens allowed to be transferred in one tx as a percent of the total supply|
|`maxWalletPercent_`|`uint256`|- amount of tokens allowed to be held in one wallet as a percent of the total supply|
|`discountFeeRequiredAmount_`|`uint256`|- the amount of tokens required to pay the discount fee|
|`discountPercent_`|`uint256`|- the percent in basis points to use as a discount|


### receive


```solidity
receive() external payable;
```

### name

*see ICoinGenieERC20 name()*


```solidity
function name() public view returns (string memory);
```

### symbol

*see ICoinGenieERC20 symbol()*


```solidity
function symbol() public view returns (string memory);
```

### decimals

*see ICoinGenieERC20 decimals()*


```solidity
function decimals() public pure returns (uint8);
```

### totalSupply

*see ICoinGenieERC20 totalSupply()*


```solidity
function totalSupply() public view override returns (uint256);
```

### feeRecipient

*see ICoinGenieERC20 feeRecipient()*


```solidity
function feeRecipient() public view returns (address payable);
```

### affiliateFeeRecipient

*see ICoinGenieERC20 affiliateFeeRecipient()*


```solidity
function affiliateFeeRecipient() public view returns (address payable);
```

### coinGenie

*see ICoinGenieERC20 coinGenie()*


```solidity
function coinGenie() public view returns (address payable);
```

### genie

*see ICoinGenieERC20 genie()*


```solidity
function genie() public view returns (address payable);
```

### isTradingOpen

*see ICoinGenieERC20 isTradingOpen()*


```solidity
function isTradingOpen() public view returns (bool);
```

### isSwapEnabled

*see ICoinGenieERC20 isSwapEnabled()*


```solidity
function isSwapEnabled() public view returns (bool);
```

### taxPercent

*see ICoinGenieERC20 taxPercent()*


```solidity
function taxPercent() public view returns (uint256);
```

### maxBuyPercent

*see ICoinGenieERC20 maxBuyPercent()*


```solidity
function maxBuyPercent() public view returns (uint256);
```

### maxWalletPercent

*see ICoinGenieERC20 maxWalletPercent()*


```solidity
function maxWalletPercent() public view returns (uint256);
```

### discountFeeRequiredAmount

*see ICoinGenieERC20 discountFeeRequiredAmount()*


```solidity
function discountFeeRequiredAmount() public view returns (uint256);
```

### discountPercent

*see ICoinGenieERC20 discountPercent()*


```solidity
function discountPercent() public view returns (uint256);
```

### lpToken

*see ICoinGenieERC20 lpToken()*


```solidity
function lpToken() public view returns (address);
```

### amountEthReceived

*see ICoinGenieERC20 balanceOf()*


```solidity
function amountEthReceived(address feeRecipient_) public view returns (uint256);
```

### balanceOf

*see ICoinGenieERC20 balanceOf()*


```solidity
function balanceOf(address account) public view override returns (uint256);
```

### burn

*see ICoinGenieERC20 burn()*


```solidity
function burn(uint256 amount) external;
```

### transfer

*see ICoinGenieERC20 transfer()*


```solidity
function transfer(address recipient, uint256 amount) public override returns (bool);
```

### allowance

*see ICoinGenieERC20 allowance()*


```solidity
function allowance(address owner, address spender) public view override returns (uint256);
```

### approve

*see ICoinGenieERC20 approve()*


```solidity
function approve(address spender, uint256 amount) public override returns (bool);
```

### transferFrom

*see ICoinGenieERC20 transferFrom()*


```solidity
function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool);
```

### manualSwap

*see ICoinGenieERC20 manualSwap()*


```solidity
function manualSwap(uint256 amount) external;
```

### createPairAndAddLiquidity

*see ICoinGenieERC20 createPairAndAddLiquidity()*


```solidity
function createPairAndAddLiquidity(
    uint256 amountToLP,
    bool payInGenie
)
    external
    payable
    onlyOwner
    nonReentrant
    returns (address);
```

### addLiquidity

*see ICoinGenieERC20 addLiquidity()*


```solidity
function addLiquidity(uint256 amountToLP, bool payInGenie) external payable nonReentrant;
```

### removeLiquidity

*see ICoinGenieERC20 removeLiquidity()*


```solidity
function removeLiquidity(uint256 amountToRemove) external nonReentrant;
```

### setGenie

*see ICoinGenieERC20 setGenie()*


```solidity
function setGenie(address genie_) external;
```

### setMaxBuyPercent

*see ICoinGenieERC20 setMaxBuyPercent()*


```solidity
function setMaxBuyPercent(uint256 maxBuyPercent_) external onlyOwner;
```

### setMaxWalletPercent

*see ICoinGenieERC20 setMaxWalletPercent()*


```solidity
function setMaxWalletPercent(uint256 maxWalletPercent_) external onlyOwner;
```

### setFeeRecipient

*see ICoinGenieERC20 setFeeRecipient()*


```solidity
function setFeeRecipient(address payable feeRecipient_) external onlyOwner;
```

### setCoinGenieFeePercent

*see ICoinGenieERC20 setCoinGenieFeePercent()*


```solidity
function setCoinGenieFeePercent(uint256 coinGenieFeePercent_) external onlyOwner;
```

### _approve

Approves a given amount for the spender.

*This is a private function to encapsulate the logic for approvals.*


```solidity
function _approve(address owner, address spender, uint256 amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the token holder.|
|`spender`|`address`|The address of the spender.|
|`amount`|`uint256`|The amount of tokens to approve.|


### _transfer

Handles the internal transfer of tokens, applying fees and taxes as needed.

*This function implements restrictions and special cases for transfers.*


```solidity
function _transfer(address from, address to, uint256 amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address sending the tokens.|
|`to`|`address`|The address receiving the tokens.|
|`amount`|`uint256`|The amount of tokens to transfer.|


### _burn

Burns a given amount of tokens from the specified address.

*Tokens are permanently removed from circulation.*


```solidity
function _burn(address from, uint256 amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address from which tokens will be burned.|
|`amount`|`uint256`|The amount of tokens to burn.|


### _addLiquidityChecks

Conducts checks for adding liquidity.

*Used to enforce trading conditions and limits.*


```solidity
function _addLiquidityChecks(uint256 amountToLP, uint256 value, address from) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToLP`|`uint256`|The amount of tokens intended for liquidity.|
|`value`|`uint256`|The amount of ETH provided for liquidity.|
|`from`|`address`|The address providing the liquidity.|


### _openTradingChecks

Checks conditions before opening trading.

*Enforces initial liquidity requirements.*


```solidity
function _openTradingChecks(uint256 amountToLP, uint256 value) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountToLP`|`uint256`|The amount of tokens intended for liquidity.|
|`value`|`uint256`|The amount of ETH provided for liquidity.|


### _checkTransferRestrictions

Validates the addresses and amounts for transfers.

*Throws errors for zero addresses or zero amounts.*


```solidity
function _checkTransferRestrictions(address from, address to, uint256 amount) private pure;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address sending the tokens.|
|`to`|`address`|The address receiving the tokens.|
|`amount`|`uint256`|The amount of tokens to transfer.|


### _swapTokensForEth

Swaps tokens for Ether.

*Utilizes Uniswap for the token-to-ETH swap.*


```solidity
function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|The amount of tokens to swap for ETH.|


### _sendEthToFee

Distributes Ether to the specified fee recipients.

*Divides and sends Ether based on predefined fee ratios.*


```solidity
function _sendEthToFee(uint256 amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The total amount of Ether to distribute.|


### _min

Returns the smaller of the two provided values.


```solidity
function _min(uint256 a, uint256 b) private pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`a`|`uint256`|First number.|
|`b`|`uint256`|Second number.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The smaller value between a and b.|


### _setERC20Properties

Sets the properties for the ERC20 token.

*Initializes the token's name, symbol, and total supply.*


```solidity
function _setERC20Properties(string memory name_, string memory symbol_, uint256 totalSupply_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the token.|
|`symbol_`|`string`|The symbol of the token.|
|`totalSupply_`|`uint256`|The total supply of the token.|


### _setFeeRecipients

Assigns addresses for fee recipients.

*Sets addresses for the main fee recipient, Coin Genie, and affiliate fee recipient.*


```solidity
function _setFeeRecipients(
    address payable feeRecipient_,
    address payable coinGenie_,
    address payable affiliateFeeRecipient_
)
    private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient_`|`address payable`|The address of the main fee recipient.|
|`coinGenie_`|`address payable`|The address for Coin Genie.|
|`affiliateFeeRecipient_`|`address payable`|The address for the affiliate fee recipient.|


### _setFeePercentages

Configures fee percentages and related parameters.

*Sets the tax percentage, max buy percentage, and other fee-related parameters.*


```solidity
function _setFeePercentages(
    uint256 taxPercent_,
    uint256 maxBuyPercent_,
    uint256 maxWalletPercent_,
    uint256 discountFeeRequiredAmount_,
    uint256 discountPercent_
)
    private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`taxPercent_`|`uint256`|The tax percentage on transactions.|
|`maxBuyPercent_`|`uint256`|The maximum buy percentage.|
|`maxWalletPercent_`|`uint256`|The maximum wallet percentage.|
|`discountFeeRequiredAmount_`|`uint256`|The discount fee required amount.|
|`discountPercent_`|`uint256`|The discount percentage.|


### _setWhitelist

Whitelists specified addresses.

*Adds provided addresses to the whitelist.*


```solidity
function _setWhitelist(address feeRecipient_, address coinGenie_, address affiliateFeeRecipient_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient_`|`address`|The address of the main fee recipient.|
|`coinGenie_`|`address`|The address for Coin Genie.|
|`affiliateFeeRecipient_`|`address`|The address for the affiliate fee recipient.|


## Structs
### FeeTakers
*The fee recipients for the contract*


```solidity
struct FeeTakers {
    address payable feeRecipient;
    address payable coinGenie;
    address payable affiliateFeeRecipient;
}
```

### FeePercentages
*The fee percentages for the contract*


```solidity
struct FeePercentages {
    uint256 taxPercent;
    uint256 maxBuyPercent;
    uint256 maxWalletPercent;
    uint256 discountFeeRequiredAmount;
    uint256 discountPercent;
    uint256 coinGenieFeePercent;
}
```

