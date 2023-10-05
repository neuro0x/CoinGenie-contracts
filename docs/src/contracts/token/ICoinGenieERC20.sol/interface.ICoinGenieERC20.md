# ICoinGenieERC20
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/b85f54c5de18f7c40c9531b0881af5e2ed6ca1a9/contracts/token/ICoinGenieERC20.sol)

**Inherits:**
IERC20


## Functions
### name


```solidity
function name() external view returns (string memory);
```

### symbol


```solidity
function symbol() external view returns (string memory);
```

### decimals


```solidity
function decimals() external pure returns (uint8);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256);
```

### feeRecipient


```solidity
function feeRecipient() external view returns (address payable);
```

### coinGenie


```solidity
function coinGenie() external view returns (address payable);
```

### genie


```solidity
function genie() external view returns (address payable);
```

### affiliateFeeRecipient


```solidity
function affiliateFeeRecipient() external view returns (address payable);
```

### isTradingOpen


```solidity
function isTradingOpen() external view returns (bool);
```

### isSwapEnabled


```solidity
function isSwapEnabled() external view returns (bool);
```

### taxPercent


```solidity
function taxPercent() external view returns (uint256);
```

### maxBuyPercent


```solidity
function maxBuyPercent() external view returns (uint256);
```

### maxWalletPercent


```solidity
function maxWalletPercent() external view returns (uint256);
```

### discountFeeRequiredAmount


```solidity
function discountFeeRequiredAmount() external view returns (uint256);
```

### lpToken


```solidity
function lpToken() external view returns (address);
```

### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### burn


```solidity
function burn(uint256 amount) external;
```

### burnFrom


```solidity
function burnFrom(address from, uint256 amount) external;
```

### transfer


```solidity
function transfer(address recipient, uint256 amount) external returns (bool);
```

### allowance


```solidity
function allowance(address owner, address spender) external view returns (uint256);
```

### approve


```solidity
function approve(address spender, uint256 amount) external returns (bool);
```

### transferFrom


```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
```

### manualSwap


```solidity
function manualSwap() external;
```

### createPairAndAddLiquidity


```solidity
function createPairAndAddLiquidity(uint256 amountToLP, bool payInGenie) external payable returns (address);
```

### addLiquidity


```solidity
function addLiquidity(uint256 amountToLP, bool payInGenie) external payable;
```

### removeLiquidity


```solidity
function removeLiquidity(uint256 amountToRemove) external;
```

### setGenie


```solidity
function setGenie(address payable genie_) external;
```

### setFeeRecipient


```solidity
function setFeeRecipient(address payable feeRecipient_) external;
```

### setTaxPercent


```solidity
function setTaxPercent(uint256 taxPercent_) external;
```

### setMaxBuyPercent


```solidity
function setMaxBuyPercent(uint256 maxBuyPercent_) external;
```

### setMaxWalletPercent


```solidity
function setMaxWalletPercent(uint256 maxWalletPercent_) external;
```

