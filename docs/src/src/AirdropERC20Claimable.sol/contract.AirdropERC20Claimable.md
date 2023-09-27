# AirdropERC20Claimable
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/3d597d9970e3bf0e8458310da2b0114698edaf81/src/AirdropERC20Claimable.sol)

**Author:**
@neuro_0x

*A contract for airdropping ERC20 tokens to specific recipients based on Merkle proofs.*


## State Variables
### airdropTokenAddress
*The address of the token to be airdropped.*


```solidity
address public airdropTokenAddress;
```


### tokenOwner
*The owner of the token to be airdropped.*


```solidity
address public tokenOwner;
```


### availableAmount
*The quantity of tokens available for airdrop.*


```solidity
uint256 public availableAmount;
```


### expirationTimestamp
*Expiration timestamp of the airdrop.*


```solidity
uint256 public expirationTimestamp;
```


### maxWalletClaimCount
*Maximum number of tokens that can be claimed by a wallet if not in the whitelist.*


```solidity
uint256 public maxWalletClaimCount;
```


### merkleRoot
*Merkle root of the whitelist.*


```solidity
bytes32 public merkleRoot;
```


### totalClaimedByWallet
*Mapping from address => total number of tokens a wallet has claimed.*


```solidity
mapping(address claimer => uint256 amount) public totalClaimedByWallet;
```


## Functions
### constructor

*Initializes the contract.*


```solidity
constructor(
    address _tokenOwner,
    address _airdropTokenAddress,
    uint256 _airdropAmount,
    uint256 _expirationTimestamp,
    uint256 _maxWalletClaimCount,
    bytes32 _merkleRoot
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenOwner`|`address`|The owner of the token to be airdropped.|
|`_airdropTokenAddress`|`address`|The address of the token to be airdropped.|
|`_airdropAmount`|`uint256`|The quantity of tokens available for airdrop.|
|`_expirationTimestamp`|`uint256`|Expiration timestamp of the airdrop.|
|`_maxWalletClaimCount`|`uint256`|Maximum number of tokens that can be claimed by a wallet if not in the whitelist.|
|`_merkleRoot`|`bytes32`|Merkle root of the whitelist.|


### claim

*Claims tokens from the airdrop.*


```solidity
function claim(uint256 amount, bytes32[] calldata proofs, uint256 proofMaxQuantityForWallet) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The quantity of tokens to claim.|
|`proofs`|`bytes32[]`|Claims proofs.|
|`proofMaxQuantityForWallet`|`uint256`|The maximum quantity of tokens that can be claimed by a wallet.|


### verifyClaim

*Verifies the claim and reverts if the claim is invalid.*


```solidity
function verifyClaim(
    address claimant,
    uint256 amount,
    bytes32[] calldata proofs,
    uint256 proofMaxQuantityForWallet
)
    public
    view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`claimant`|`address`|The address of the claimer.|
|`amount`|`uint256`|The quantity of tokens to claim.|
|`proofs`|`bytes32[]`|Claims proofs.|
|`proofMaxQuantityForWallet`|`uint256`|The maximum quantity of tokens that can be claimed by a wallet.|


### _transferClaimedTokens

*Transfers the claimed tokens to the recipient.*


```solidity
function _transferClaimedTokens(address recipient, uint256 amount) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient of the tokens.|
|`amount`|`uint256`|The quantity of tokens to claim.|


## Events
### TokensClaimed
*Emitted when tokens are claimed*


```solidity
event TokensClaimed(address indexed claimer, uint256 quantityClaimed);
```

## Errors
### InvalidTransferAmount

```solidity
error InvalidTransferAmount();
```

### AirdropExpired

```solidity
error AirdropExpired();
```

### AlreadyClaimedMax

```solidity
error AlreadyClaimedMax();
```

### TransferFailed

```solidity
error TransferFailed();
```

### InvalidAirdropParameters

```solidity
error InvalidAirdropParameters(address tokenOwner, address airdropTokenAddress, uint256 airdropAmount);
```

