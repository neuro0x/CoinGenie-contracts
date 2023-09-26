# LiquidityLocker
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/1dd7a56098d73502ffaeefe45808c9c4168197e8/src/LiquidityLocker.sol)

**Inherits:**
Ownable, ReentrancyGuard

**Author:**
@neuro_0x

*A contract for locking Uniswap V2 liquidity pool tokens for specified periods.*


## State Variables
### fee

```solidity
uint256 public fee;
```


### feeRecipient

```solidity
address public feeRecipient;
```


### _UNISWAP_V2_FACTORY

```solidity
IUniswapV2Factory private constant _UNISWAP_V2_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
```


### _users

```solidity
mapping(address userAddress => User user) private _users;
```


### _lockedTokens

```solidity
EnumerableSet.AddressSet private _lockedTokens;
```


### tokenLocks

```solidity
mapping(address pair => TokenLock[] locks) public tokenLocks;
```


### migrator

```solidity
IUniswapV2Migrator public migrator;
```


## Functions
### constructor

*Creates a new LiquidityLocker contract*


```solidity
constructor(uint256 _fee, address _feeRecipient);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|The fee amount to use|
|`_feeRecipient`|`address`|The address to send fees to|


### setFee

*Set the fee amount*


```solidity
function setFee(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The fee amount to use|


### setFeeRecipient

*Set the fee recipient*


```solidity
function setFeeRecipient(address feeRecipient_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeRecipient_`|`address`|The address to send fees to|


### setMigrator

*Set the migrator contract which allows locked lp tokens to be migrated to uniswap v3*


```solidity
function setMigrator(IUniswapV2Migrator _migrator) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_migrator`|`IUniswapV2Migrator`|The address of the migrator contract|


### lockLPToken

*Creates a new lock*


```solidity
function lockLPToken(
    IERC20 lpToken,
    uint256 amountOfLPToLock,
    uint256 unlockDate,
    address payable withdrawer
)
    external
    payable
    nonReentrant
    returns (TokenLock memory tokenLock);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lpToken`|`IERC20`|the univ2 token address|
|`amountOfLPToLock`|`uint256`|amount of LP tokens to lock|
|`unlockDate`|`uint256`|the unix timestamp (in seconds) until unlock|
|`withdrawer`|`address payable`|the user who can withdraw liquidity once the lock expires|


### relock

*extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
this prevents errors when a user performs multiple tx per block possibly with varying gas prices*


```solidity
function relock(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _unlockDate) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lpToken`|`IERC20`|the univ2 token address|
|`_index`|`uint256`|the index of the lock for the token|
|`_lockID`|`uint256`|the lockID of the lock for the token|
|`_unlockDate`|`uint256`|the new unix timestamp (in seconds) until unlock|


### withdraw

*withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
this prevents errors when a user performs multiple tx per block possibly with varying gas prices*


```solidity
function withdraw(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant;
```

### incrementLock

*increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees,
and faster loading on our live block explorer*


```solidity
function incrementLock(
    IERC20 _lpToken,
    uint256 _index,
    uint256 _lockID,
    uint256 _amount
)
    external
    nonReentrant
    returns (TokenLock memory _userLock);
```

### transferLockOwnership

*transfer a lock to a new owner, e.g. presale project -> project owner*


```solidity
function transferLockOwnership(address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external;
```

### migrate

*migrates liquidity to uniswap v3*


```solidity
function migrate(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant;
```

### getNumLocksForToken

*Get the number of locks for a specific token.*


```solidity
function getNumLocksForToken(address _lpToken) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lpToken`|`address`|The address of the LP token.|


### getNumLockedTokens

*Get the total number of locked tokens*


```solidity
function getNumLockedTokens() external view returns (uint256);
```

### getLockedTokenAtIndex

*Get the address of a locked token at an index.*


```solidity
function getLockedTokenAtIndex(uint256 _index) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_index`|`uint256`|The index of the token.|


### getUserNumLockedTokens

*Get the number of tokens a user has locked.*


```solidity
function getUserNumLockedTokens(address _user) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|The address of the user.|


### getUserLockedTokenAtIndex

*Get the token address a user has locked at an index.*


```solidity
function getUserLockedTokenAtIndex(address _user, uint256 _index) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|The address of the user.|
|`_index`|`uint256`|The index of the token.|


### getUserNumLocksForToken

*Get the number of locks for a specific user and token.*


```solidity
function getUserNumLocksForToken(address _user, address _lpToken) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|The address of the user.|
|`_lpToken`|`address`|The address of the LP token.|


### getUserLockForTokenAtIndex

*Get the lock for a specific user and token at an index.*


```solidity
function getUserLockForTokenAtIndex(
    address _user,
    address _lpToken,
    uint256 _index
)
    external
    view
    returns (uint256, uint256, uint256, uint256, uint256, address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|The address of the user.|
|`_lpToken`|`address`|The address of the LP token.|
|`_index`|`uint256`|The index of the lock.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The lock date.|
|`<none>`|`uint256`|Amount of tokens locked.|
|`<none>`|`uint256`|Initial amount of tokens locked.|
|`<none>`|`uint256`|Unlock date of the lock.|
|`<none>`|`uint256`|Lock ID of the lock.|
|`<none>`|`address`|Owner of the lock.|


## Events
### OnWithdraw

```solidity
event OnWithdraw(address lpToken, uint256 amount);
```

### OnDeposit

```solidity
event OnDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
```

## Errors
### InvalidAmount

```solidity
error InvalidAmount();
```

### InvalidRecipient

```solidity
error InvalidRecipient();
```

### InvalidLockDate

```solidity
error InvalidLockDate();
```

### LockMismatch

```solidity
error LockMismatch();
```

### BeforeUnlockDate

```solidity
error BeforeUnlockDate();
```

### OwnerAlreadySet

```solidity
error OwnerAlreadySet();
```

### MigratorNotSet

```solidity
error MigratorNotSet();
```

### NotUniPair

```solidity
error NotUniPair(address lpToken);
```

## Structs
### User

```solidity
struct User {
    EnumerableSet.AddressSet lockedTokens;
    mapping(address => uint256[]) locksForToken;
}
```

### TokenLock

```solidity
struct TokenLock {
    uint256 lockDate;
    uint256 amount;
    uint256 initialAmount;
    uint256 unlockDate;
    uint256 lockID;
    address owner;
}
```

