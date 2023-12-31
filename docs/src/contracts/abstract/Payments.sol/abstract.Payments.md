# Payments
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/65dc6cf5f97d3390f866cb15091adfd179cd1ab1/contracts/abstract/Payments.sol)

**Inherits:**
Ownable, ReentrancyGuard

**Author:**
@neuro_0x

This contract is used to split payments between multiple parties, and track and affiliates and their fees


## State Variables
### _MAX_BPS
*The maximum amount of basis points*


```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### _MAX_SHARES
*The maximum shares*


```solidity
uint256 private constant _MAX_SHARES = 100;
```


### _UNISWAP_V2_ROUTER
*The address of the Uniswap V2 Router*


```solidity
IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _totalShares
*The total amount of shares*


```solidity
uint256 internal _totalShares;
```


### _totalReleased
*The total amount of released payments*


```solidity
uint256 internal _totalReleased;
```


### _affiliatePayoutOwed
*The total amount of affiliate fees owed*


```solidity
uint256 internal _affiliatePayoutOwed;
```


### _affiliateFeePercent
*The affiliate fee percentage*


```solidity
uint256 internal _affiliateFeePercent = 2000;
```


### _shares
*The mapping of shares for each payee*


```solidity
mapping(address payee => uint256 shares) internal _shares;
```


### _released
*The mapping of released payments for each payee*


```solidity
mapping(address payee => uint256 released) internal _released;
```


### _amountReceivedFromAffiliate
*The mapping of amount received from each affiliate*


```solidity
mapping(address affiliate => uint256 amountReceived) internal _amountReceivedFromAffiliate;
```


### _amountPaidToAffiliate
*The mapping of amount paid to each affiliate*


```solidity
mapping(address affiliate => uint256 amountPaid) internal _amountPaidToAffiliate;
```


### _amountOwedToAffiliate
*The mapping of amount owed to each affiliate*


```solidity
mapping(address affiliate => uint256 amountOwed) internal _amountOwedToAffiliate;
```


### _tokensReferredByAffiliate
*The mapping of tokens referred by each affiliate*


```solidity
mapping(address affiliate => address[] tokensReferred) internal _tokensReferredByAffiliate;
```


### _isTokenReferredByAffiliate
*The mapping of tokens referred by each affiliate*


```solidity
mapping(address affiliate => mapping(address tokenAddress => bool)) internal _isTokenReferredByAffiliate;
```


### _amountEarnedByAffiliateByToken
*The mapping of amount earned by each affiliate for each token*


```solidity
mapping(address affiliate => mapping(address tokenAddress => uint256 amountOwed)) internal
    _amountEarnedByAffiliateByToken;
```


### _payees
*The array of payees*


```solidity
address[] private _payees;
```


### affiliates
*The array of affiliates*


```solidity
address[] public affiliates;
```


## Functions
### receive

*Extending contract should override this function and emit this event*


```solidity
receive() external payable virtual;
```

### totalShares


```solidity
function totalShares() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total amount of shares|


### totalReleased


```solidity
function totalReleased() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total amount of released payments|


### shares


```solidity
function shares(address account) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the account to get the shares for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of shares for an account|


### released


```solidity
function released(address account) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the account to get the released payments for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of released payments for an account|


### payee


```solidity
function payee(uint256 index) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`index`|`uint256`|the index of the payee to get|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|the address of the payee|


### payeeCount


```solidity
function payeeCount() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the number of payees|


### amountOwedToAllAffiliates


```solidity
function amountOwedToAllAffiliates() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total amount of affiliate fees owed|


### amountOwedToAffiliate


```solidity
function amountOwedToAffiliate(address account) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the affiliate account to get the amount owed to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total amount owed to an affiliate|


### amountPaidToAffiliate


```solidity
function amountPaidToAffiliate(address account) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the affiliate account to get the amount paid to|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total amount paid to an affiliate|


### getAffiliates


```solidity
function getAffiliates() public view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|the array of affiliates|


### getNumberOfAffiliates


```solidity
function getNumberOfAffiliates() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the number of affiliates|


### getTokensReferredByAffiliate


```solidity
function getTokensReferredByAffiliate(address account) public view returns (address[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the affiliate account to get the tokens referred by|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|the tokens referred by an affiliate|


### amountEarnedByAffiliateByToken


```solidity
function amountEarnedByAffiliateByToken(address account, address tokenAddress) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the affiliate account to get the amount earned from|
|`tokenAddress`|`address`|the token address to get the amount earned from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount earned from an affiliate for a token|


### affiliateFeePercent


```solidity
function affiliateFeePercent() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the affiliate fee percent|


### affiliateRelease


```solidity
function affiliateRelease(address payable account, address genie_) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address payable`|the affiliate to release payment to|
|`genie_`|`address`|the address of the CoinGenie ERC20 $GENIE token|


### setAffiliatePercent

*Set the affiliate fee percent*


```solidity
function setAffiliatePercent(uint256 newAffiliatePercent) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newAffiliatePercent`|`uint256`|the new affiliate percent|


### release

*Pay a team member*


```solidity
function release(address payable account) external virtual nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address payable`|the account to release payment to|


### updateSplit

*Update the split*


```solidity
function updateSplit(address[] calldata payees_, uint256[] calldata shares_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`payees_`|`address[]`|the payees|
|`shares_`|`uint256[]`|the shares of the payees|


### _createSplit

*Called on contract creation to set the initial payees and shares*


```solidity
function _createSplit(address[] memory payees, uint256[] memory shares_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`payees`|`address[]`|the array of payees|
|`shares_`|`uint256[]`|the array of shares|


### _pendingPayment

*Helper function to get the pending payment for an account*


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
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the account to get the pending payment for|
|`totalReceived`|`uint256`|the total amount received|
|`alreadyReleased`|`uint256`|the amount already released|


### _addPayee

*Add a payee*


```solidity
function _addPayee(address account, uint256 shares_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the account to add as a payee|
|`shares_`|`uint256`|the amount of shares for the payee|


## Events
### ShareUpdated
*The event emitted when a share is updated*


```solidity
event ShareUpdated(address indexed account, uint256 indexed shares);
```

### PayeeAdded
*The event emitted when a payee is added*


```solidity
event PayeeAdded(address indexed account, uint256 indexed shares);
```

### PaymentReleased
*The event emitted when a payment is released*


```solidity
event PaymentReleased(address indexed to, uint256 indexed amount);
```

### PaymentReceived
*The event emitted when a payment is received*


```solidity
event PaymentReceived(address indexed from, uint256 indexed amount);
```

## Errors
### NoPayees
*The error emitted when there are no payees*


```solidity
error NoPayees();
```

### PaymentFailed
*The error emitted when a payment fails*


```solidity
error PaymentFailed();
```

### SharesAreZero
*The error emitted when shares are zero*


```solidity
error SharesAreZero();
```

### GenieAlreadySet
*The error emitted when the genie is already set*


```solidity
error GenieAlreadySet();
```

### AccountIsZeroAddress
*The error emitted when the account is a zero address*


```solidity
error AccountIsZeroAddress();
```

### NoAmountOwedToAffiliate
*The error emitted when there is no amount owed to an affiliate*


```solidity
error NoAmountOwedToAffiliate();
```

### AccountAlreadyHasShares
*The error emitted when an account already has shares*


```solidity
error AccountAlreadyHasShares();
```

### InvalidShares
*The error emitted when the shares are invalid*


```solidity
error InvalidShares(uint256 shares);
```

### AccountNotDuePayment
*The error emitted when an account is not due payment*


```solidity
error AccountNotDuePayment(address account);
```

### ZeroSharesForAccount
*The error emitted when there are no shares for an account*


```solidity
error ZeroSharesForAccount(address account);
```

### InvalidAffiliatePercent
*The error emitted when the affiliate percent is invalid*


```solidity
error InvalidAffiliatePercent(uint256 affiliatePercent, uint256 maxBps);
```

### PayeeShareLengthMisMatch
*The error emitted when the payee and shares lengths do not match*


```solidity
error PayeeShareLengthMisMatch(uint256 payeesLength, uint256 sharesLength);
```

