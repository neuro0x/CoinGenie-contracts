# Payments
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/23e9975ccf154969f8aabc50637080b24f12bd6c/contracts/abstract/Payments.sol)

**Inherits:**
Ownable

**Author:**
@neuro_0x

*This contract is used to split payments between multiple parties, and track and affiliate fees.*


## State Variables
### _MAX_BPS

```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### _UNISWAP_V2_ROUTER

```solidity
IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _genie

```solidity
address payable internal _genie;
```


### _totalShares

```solidity
uint256 internal _totalShares;
```


### _totalReleased

```solidity
uint256 internal _totalReleased;
```


### _releaseAmount

```solidity
uint256 internal _releaseAmount;
```


### _affiliateFeePercent

```solidity
uint256 internal _affiliateFeePercent = 2000;
```


### _shares

```solidity
mapping(address payee => uint256 shares) internal _shares;
```


### _released

```solidity
mapping(address payee => uint256 released) internal _released;
```


### _amountReceivedFromAffiliate

```solidity
mapping(address affiliate => uint256 receivedFrom) internal _amountReceivedFromAffiliate;
```


### _amountPaidToAffiliate

```solidity
mapping(address affiliate => uint256 amountPaid) internal _amountPaidToAffiliate;
```


### _amountOwedToAffiliate

```solidity
mapping(address affiliate => uint256 amountOwed) internal _amountOwedToAffiliate;
```


### _tokensReferredByAffiliate

```solidity
mapping(address affiliate => address[] tokensReferred) internal _tokensReferredByAffiliate;
```


### _amountEarnedByAffiliateByToken

```solidity
mapping(address affiliate => mapping(address tokenAddress => uint256 amountOwed)) internal
    _amountEarnedByAffiliateByToken;
```


### _payees

```solidity
address[] private _payees;
```


### _affiliates

```solidity
address[] private _affiliates;
```


### _affiliateTokens

```solidity
address[] private _affiliateTokens;
```


## Functions
### receive


```solidity
receive() external payable virtual;
```

### genie

Below is a sample implementation of how this function should be overridden.


```solidity
function genie() public view virtual returns (address payable);
```

### totalShares


```solidity
function totalShares() public view returns (uint256);
```

### totalReleased


```solidity
function totalReleased() public view returns (uint256);
```

### shares


```solidity
function shares(address account) public view returns (uint256);
```

### released


```solidity
function released(address account) public view returns (uint256);
```

### payee


```solidity
function payee(uint256 index) public view returns (address);
```

### payeeCount


```solidity
function payeeCount() public view returns (uint256);
```

### amountOwedToAffiliate


```solidity
function amountOwedToAffiliate(address account) public view returns (uint256);
```

### amountPaidToAffiliate


```solidity
function amountPaidToAffiliate(address account) public view returns (uint256);
```

### getTokensOfAffiliate


```solidity
function getTokensOfAffiliate(address account) public view returns (address[] memory);
```

### amountEarnedByAffiliateByToken


```solidity
function amountEarnedByAffiliateByToken(address affiliate, address tokenAddress) public view returns (uint256);
```

### affiliateCount


```solidity
function affiliateCount() public view returns (uint256);
```

### affiliateRelease


```solidity
function affiliateRelease(address payable affiliate) external;
```

### release


```solidity
function release(address payable account) public virtual;
```

### resetSplit


```solidity
function resetSplit(address[] memory payees, uint256[] memory shares_) external onlyOwner;
```

### setGenie


```solidity
function setGenie(address payable genie_) external onlyOwner;
```

### _createSplit


```solidity
function _createSplit(address[] memory payees, uint256[] memory shares_) internal;
```

### _pendingPayment


```solidity
function _pendingPayment(
    address account,
    uint256 totalReceived,
    uint256 alreadyReleased
)
    internal
    view
    returns (uint256);
```

### _addPayee


```solidity
function _addPayee(address account, uint256 shares_) private;
```

## Events
### PayeeAdded

```solidity
event PayeeAdded(address account, uint256 shares);
```

### PaymentReleased

```solidity
event PaymentReleased(address to, uint256 amount);
```

### PaymentReceived

```solidity
event PaymentReceived(address from, uint256 amount);
```

## Errors
### NoPayees

```solidity
error NoPayees();
```

### PaymentFailed

```solidity
error PaymentFailed();
```

### SharesAreZero

```solidity
error SharesAreZero();
```

### GenieAlreadySet

```solidity
error GenieAlreadySet();
```

### AccountIsZeroAddress

```solidity
error AccountIsZeroAddress();
```

### NoAmountOwedToAffiliate

```solidity
error NoAmountOwedToAffiliate();
```

### AccountAlreadyHasShares

```solidity
error AccountAlreadyHasShares();
```

### AccountNotDuePayment

```solidity
error AccountNotDuePayment(address account);
```

### ZeroSharesForAccount

```solidity
error ZeroSharesForAccount(address account);
```

### PayeeShareLengthMisMatch

```solidity
error PayeeShareLengthMisMatch(uint256 payeesLength, uint256 sharesLength);
```

