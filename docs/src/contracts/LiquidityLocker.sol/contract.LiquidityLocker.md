# LiquidityLocker
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/65dc6cf5f97d3390f866cb15091adfd179cd1ab1/contracts/LiquidityLocker.sol)

**Inherits:**
Ownable, ReentrancyGuard

**Author:**
@neuro_0x

*A contract for locking Uniswap V2 liquidity pool tokens for specified periods*


## State Variables
### fee
*The fee amount to use*


```solidity
uint256 public fee;
```


### feeRecipient
*The address to send fees to*


```solidity
address public feeRecipient;
```


### _UNISWAP_V2_FACTORY
*The Uniswap V2 factory address*


```solidity
IUniswapV2Factory private constant _UNISWAP_V2_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
```


### _users
*A mapping of user addresses to User structs*


```solidity
mapping(address userAddress => User user) private _users;
```


### _lockedTokens
*A set of all locked tokens*


```solidity
EnumerableSet.AddressSet private _lockedTokens;
```


### tokenLocks
*A mapping of univ2 pair addresses to TokenLock structs*


```solidity
mapping(address pair => TokenLock[] locks) public tokenLocks;
```


### migrator
*The migrator contract which allows locked lp tokens to be migrated to uniswap v3*


```solidity
IUniswapV2Migrator public migrator;
```


## Functions
### constructor

*Creates a new LiquidityLocker contract*


```solidity
constructor(uint256 _fee, address _feeRecipient) payable;
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
function setMigrator(IUniswapV2Migrator _migrator) external onlyOwner;
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

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenLock`|`TokenLock`|- the token lock object created|


### relock

*extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed this prevents
errors when a user performs multiple tx per block possibly with varying gas prices*


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

*withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed this
prevents errors when a user performs multiple tx per block possibly with varying gas prices*


```solidity
function withdraw(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lpToken`|`IERC20`|the univ2 token address|
|`_index`|`uint256`|the index of the lock for the token|
|`_lockID`|`uint256`|the lockID of the lock for the token|
|`_amount`|`uint256`|the amount to withdraw|


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
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lpToken`|`IERC20`|the univ2 token address|
|`_index`|`uint256`|the index of the lock for the token|
|`_lockID`|`uint256`|the lockID of the lock for the token|
|`_amount`|`uint256`|the amount to increment the lock by|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_userLock`|`TokenLock`|- the token lock object updated|


### transferLockOwnership

*transfer a lock to a new owner, e.g. presale project -> project owner*


```solidity
function transferLockOwnership(address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lpToken`|`address`|the univ2 token address|
|`_index`|`uint256`|the index of the lock for the token|
|`_lockID`|`uint256`|the lockID of the lock for the token|
|`_newOwner`|`address payable`|the address of the new owner|


### migrate

*migrates liquidity to uniswap v3*


```solidity
function migrate(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lpToken`|`IERC20`|the univ2 token address|
|`_index`|`uint256`|the index of the lock for the token|
|`_lockID`|`uint256`|the lockID of the lock for the token|
|`_amount`|`uint256`|the amount to migrate|


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
### FeeSet
Emitted when the fee is set


```solidity
event FeeSet(uint256 indexed fee);
```

### MigratorSet
Emitted when the migrator is set


```solidity
event MigratorSet(address indexed migrator);
```

### FeeRecipientSet
Emitted when the fee recipient is set


```solidity
event FeeRecipientSet(address indexed feeRecipient);
```

### LockOwnershipTransfered
Emitted when the lock ownership is transferred


```solidity
event LockOwnershipTransfered(address indexed newOwner);
```

### OnWithdraw
Emitted when tokens are withdrawn


```solidity
event OnWithdraw(address indexed lpToken, uint256 indexed amount);
```

### Migrated
Emitted when tokens are migrated


```solidity
event Migrated(address indexed user, address indexed lpToken, uint256 indexed amount);
```

### OnRelock
Emitted when the lock is relocked


```solidity
event OnRelock(address indexed user, address indexed lpToken, uint256 indexed unlockDate);
```

### OnDeposit
Emitted when tokens are deposited


```solidity
event OnDeposit(
    address lpToken, address indexed user, uint256 amount, uint256 indexed lockDate, uint256 indexed unlockDate
);
```

## Errors
### LockMismatch
Reverts when the lock is a mismatch


```solidity
error LockMismatch();
```

### InvalidAmount
Reverts when the amount is invalid


```solidity
error InvalidAmount();
```

### MigratorNotSet
Reverts when the migrator is not set


```solidity
error MigratorNotSet();
```

### InvalidLockDate
Reverts when the lock date is invalid


```solidity
error InvalidLockDate();
```

### OwnerAlreadySet
Reverts when the owner is already set


```solidity
error OwnerAlreadySet();
```

### InvalidRecipient
Reverts when the recipient is already set


```solidity
error InvalidRecipient();
```

### BeforeUnlockDate
Reverts when the lock is before the unlock date


```solidity
error BeforeUnlockDate();
```

### NotUniPair
Reverts when the LP Token is not a univ2 pair


```solidity
error NotUniPair(address lpToken);
```

### TransferFailed
Reverts when the transfer fails


```solidity
error TransferFailed(uint256 amount, address from, address to);
```

## Structs
### User
*The user struct records all the locked tokens for a user*


```solidity
struct User {
    EnumerableSet.AddressSet lockedTokens;
    mapping(address => uint256[]) locksForToken;
}
```

### TokenLock
*The token lock struct records all the data for a lock*


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

