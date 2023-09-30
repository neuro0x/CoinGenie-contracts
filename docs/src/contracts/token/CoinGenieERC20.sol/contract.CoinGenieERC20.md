# CoinGenieERC20
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/23e9975ccf154969f8aabc50637080b24f12bd6c/contracts/token/CoinGenieERC20.sol)

**Inherits:**
[ICoinGenieERC20](/contracts/token/ICoinGenieERC20.sol/interface.ICoinGenieERC20.md), Ownable, ReentrancyGuard

**Author:**
@neuro_0x

A robust and secure ERC20 token for the Coin Genie ecosystem. Inspired by APEX & TokenTool by Bitbond

THIS ERC20 SHOULD ONLY BE DEPLOYED FROM THE COINGENIE ERC20 FACTORY


## State Variables
### _DECIMALS

```solidity
uint8 private constant _DECIMALS = 18;
```


### _MAX_BPS

```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### _MAX_TAX

```solidity
uint256 private constant _MAX_TAX = 2000;
```


### _MIN_LIQUIDITY_ETH

```solidity
uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;
```


### _MIN_LIQUIDITY_TOKEN

```solidity
uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;
```


### _COIN_GENIE_FEE

```solidity
uint256 private constant _COIN_GENIE_FEE = 100;
```


### _LP_ETH_FEE_PERCENTAGE

```solidity
uint256 private constant _LP_ETH_FEE_PERCENTAGE = 100;
```


### _UNISWAP_V2_ROUTER

```solidity
IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _balances

```solidity
mapping(address holder => uint256 balance) private _balances;
```


### _allowances

```solidity
mapping(address holder => mapping(address spender => uint256 allowance)) private _allowances;
```


### _whitelist

```solidity
mapping(address holder => bool isWhiteListed) private _whitelist;
```


### _feeTakers

```solidity
FeeTakers private _feeTakers;
```


### _feePercentages

```solidity
FeePercentages private _feePercentages;
```


### _genie

```solidity
CoinGenieERC20 private _genie;
```


### _uniswapV2Pair

```solidity
address private _uniswapV2Pair;
```


### _isTradingOpen

```solidity
bool private _isTradingOpen;
```


### _inSwap

```solidity
bool private _inSwap;
```


### _isSwapEnabled

```solidity
bool private _isSwapEnabled;
```


### _name

```solidity
string private _name;
```


### _symbol

```solidity
string private _symbol;
```


### _totalSupply

```solidity
uint256 private _totalSupply;
```


## Functions
### lockTheSwap


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
    uint256 deflationPercent_,
    uint256 maxBuyPercent_,
    uint256 maxWalletPercent_,
    uint256 discountFeeRequiredAmount_
);
```

### receive


```solidity
receive() external payable;
```

### name


```solidity
function name() public view returns (string memory);
```

### symbol


```solidity
function symbol() public view returns (string memory);
```

### decimals


```solidity
function decimals() public pure returns (uint8);
```

### totalSupply


```solidity
function totalSupply() public view override returns (uint256);
```

### feeRecipient


```solidity
function feeRecipient() public view returns (address payable);
```

### coinGenie


```solidity
function coinGenie() public view returns (address payable);
```

### genie


```solidity
function genie() public view returns (address payable);
```

### affiliateFeeRecipient


```solidity
function affiliateFeeRecipient() public view returns (address payable);
```

### isTradingOpen


```solidity
function isTradingOpen() public view returns (bool);
```

### isSwapEnabled


```solidity
function isSwapEnabled() public view returns (bool);
```

### isDeflationary


```solidity
function isDeflationary() public view returns (bool);
```

### taxPercent


```solidity
function taxPercent() public view returns (uint256);
```

### deflationPercent


```solidity
function deflationPercent() public view returns (uint256);
```

### maxBuyPercent


```solidity
function maxBuyPercent() public view returns (uint256);
```

### maxWalletPercent


```solidity
function maxWalletPercent() public view returns (uint256);
```

### discountFeeRequiredAmount


```solidity
function discountFeeRequiredAmount() public view returns (uint256);
```

### lpToken


```solidity
function lpToken() public view returns (address);
```

### balanceOf


```solidity
function balanceOf(address account) public view override returns (uint256);
```

### burn


```solidity
function burn(uint256 amount) public;
```

### burnFrom


```solidity
function burnFrom(address from, uint256 amount) public;
```

### transfer


```solidity
function transfer(address recipient, uint256 amount) public override returns (bool);
```

### allowance


```solidity
function allowance(address owner, address spender) public view override returns (uint256);
```

### approve


```solidity
function approve(address spender, uint256 amount) public override returns (bool);
```

### transferFrom


```solidity
function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool);
```

### manualSwap


```solidity
function manualSwap() external;
```

### createPairAndAddLiquidity


```solidity
function createPairAndAddLiquidity(uint256 amountToLP, bool payInGenie) external payable onlyOwner returns (address);
```

### addLiquidity


```solidity
function addLiquidity(uint256 amountToLP, bool payInGenie) external payable nonReentrant;
```

### removeLiquidity


```solidity
function removeLiquidity(uint256 amountToRemove) external;
```

### setGenie


```solidity
function setGenie(address payable genie_) external;
```

### setTaxPercent


```solidity
function setTaxPercent(uint256 taxPercent_) external onlyOwner;
```

### setDeflationPercent


```solidity
function setDeflationPercent(uint256 deflationPercent_) external onlyOwner;
```

### setMaxBuyPercent


```solidity
function setMaxBuyPercent(uint256 maxBuyPercent_) external onlyOwner;
```

### setMaxWalletPercent


```solidity
function setMaxWalletPercent(uint256 maxWalletPercent_) external onlyOwner;
```

### setFeeRecipient


```solidity
function setFeeRecipient(address payable feeRecipient_) external onlyOwner;
```

### _approve


```solidity
function _approve(address owner, address spender, uint256 amount) private;
```

### _transfer


```solidity
function _transfer(address from, address to, uint256 amount) private;
```

### _burn


```solidity
function _burn(address from, uint256 amount) private;
```

### _openTradingChecks


```solidity
function _openTradingChecks(uint256 amountToLP, uint256 value) private view;
```

### _checkTransferRestrictions


```solidity
function _checkTransferRestrictions(address from, address to, uint256 amount) private pure;
```

### _checkBuyRestrictions


```solidity
function _checkBuyRestrictions(address to, uint256 amount) private view;
```

### _swapTokensForEth


```solidity
function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap;
```

### _sendEthToFee


```solidity
function _sendEthToFee(uint256 amount) private;
```

### _min


```solidity
function _min(uint256 a, uint256 b) private pure returns (uint256);
```

### _setERC20Properties


```solidity
function _setERC20Properties(string memory name_, string memory symbol_, uint256 totalSupply_) private;
```

### _setFeeRecipients


```solidity
function _setFeeRecipients(
    address payable feeRecipient_,
    address payable coinGenie_,
    address payable affiliateFeeRecipient_
)
    private;
```

### _setFeePercentages


```solidity
function _setFeePercentages(
    uint256 taxPercent_,
    uint256 deflationPercent_,
    uint256 maxBuyPercent_,
    uint256 maxWalletPercent_,
    uint256 discountFeeRequiredAmount_
)
    private;
```

### _setWhitelist


```solidity
function _setWhitelist(address feeRecipient_, address coinGenie_, address affiliateFeeRecipient_) private;
```

## Events
### TradingOpened

```solidity
event TradingOpened(address indexed pair);
```

## Errors
### GenieAlreadySet

```solidity
error GenieAlreadySet();
```

### ApproveFromZeroAddress

```solidity
error ApproveFromZeroAddress();
```

### BurnFromZeroAddress

```solidity
error BurnFromZeroAddress();
```

### TransferFromZeroAddress

```solidity
error TransferFromZeroAddress();
```

### TradingAlreadyOpen

```solidity
error TradingAlreadyOpen();
```

### Unauthorized

```solidity
error Unauthorized();
```

### InsufficientETH

```solidity
error InsufficientETH(uint256 amount, uint256 minAmount);
```

### ExceedsMaxAmount

```solidity
error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);
```

### InsufficientTokens

```solidity
error InsufficientTokens(uint256 amount, uint256 minAmount);
```

### InsufficientAllowance

```solidity
error InsufficientAllowance(uint256 amount, uint256 allowance);
```

### TransferFailed

```solidity
error TransferFailed(uint256 amount, address from, address to);
```

## Structs
### FeeTakers

```solidity
struct FeeTakers {
    address payable feeRecipient;
    address payable coinGenie;
    address payable affiliateFeeRecipient;
}
```

### FeePercentages

```solidity
struct FeePercentages {
    uint256 taxPercent;
    uint256 deflationPercent;
    uint256 maxBuyPercent;
    uint256 maxWalletPercent;
    uint256 discountFeeRequiredAmount;
}
```

