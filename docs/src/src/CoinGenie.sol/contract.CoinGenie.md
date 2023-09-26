# CoinGenie
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/6513d4b92c3fc6307b36cde8f44463c03d16d8b4/src/CoinGenie.sol)

**Inherits:**
Ownable, ReentrancyGuard

**Author:**
@neuro_0x

*The orchestrator contract for the CoinGenie ecosystem.*


## State Variables
### _MAX_BPS
*The maximum basis points value.*


```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### UNISWAP_V2_ROUTER
*The address of the Uniswap V2 Router. The contract uses the router for liquidity provision and token swaps*


```solidity
IUniswapV2Router02 public constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _payouts
*A mapping of payout categories to payouts.*


```solidity
mapping(PayoutCategory category => Payout payout) private _payouts;
```


### _erc20Factory
*Stores the address of the ERC20Factory contract.*


```solidity
ERC20Factory private _erc20Factory;
```


### _airdropClaimableERC20Factory
*Stores the address of the AirdropERC20Claimable contract.*


```solidity
AirdropERC20ClaimableFactory private _airdropClaimableERC20Factory;
```


### createdClaimableAirdrops
*Stores the addresses of all airdrops launched by the contract.*


```solidity
address[] public createdClaimableAirdrops;
```


### claimableAirdropCreatedBy
*A mapping of airdrops launched by a specific owner.*


```solidity
mapping(address user => ClaimableAirdrop[] airdrops) public claimableAirdropCreatedBy;
```


### launchedTokens
*Stores the addresses of all tokens launched by the contract.*


```solidity
address[] public launchedTokens;
```


### tokensLaunchedBy
*A mapping of tokens launched by a specific owner.*


```solidity
mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;
```


## Functions
### onlyTeamMember

Modifier to ensure that the caller is a team member.


```solidity
modifier onlyTeamMember();
```

### constructor

Construct the CoinGenie contract.


```solidity
constructor(address erc20FactoryAddress, address airdropClaimableERC20FactoryAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`erc20FactoryAddress`|`address`|The address of the ERC20Factory contract|
|`airdropClaimableERC20FactoryAddress`|`address`|The address of the AirdropERC20ClaimableFactory contract|


### receive


```solidity
receive() external payable;
```

### launchToken

Launch a new instance of the ERC20.

*This function deploys a new token contract and initializes it with provided parameters.*


```solidity
function launchToken(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address tokenOwner,
    bool isBurnable,
    bool isPausable,
    bool isDeflationary,
    uint256 maxPerWallet,
    address affiliateFeeRecipient,
    address feeRecipient,
    uint256 feePercentage,
    uint256 burnPercentage
)
    external
    returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|The name of the token|
|`symbol`|`string`|The symbol of the token|
|`initialSupply`|`uint256`|The initial supply of the token|
|`tokenOwner`|`address`|The address that will be the owner of the token|
|`isBurnable`|`bool`|Whether the token is burnable|
|`isPausable`|`bool`|Whether the token is pausable|
|`isDeflationary`|`bool`|Whether the token is deflationary|
|`maxPerWallet`|`uint256`|The maximum amount of tokens allowed to be held by one wallet|
|`affiliateFeeRecipient`|`address`|The address to receive the affiliate fee|
|`feeRecipient`|`address`|The address to receive the tax fees|
|`feePercentage`|`uint256`|The percent in basis points to use as a tax|
|`burnPercentage`|`uint256`|The percent in basis points to burn on every tx if this token is deflationary|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|_tokenAddress The address of the newly deployed token contract|


### createClaimableAirdrop

Launch a new instance of the CoinGenieAirdropClaimable Contract.


```solidity
function createClaimableAirdrop(
    address tokenOwner,
    address airdropTokenAddress,
    uint256 airdropAmount,
    uint256 expirationTimestamp,
    uint256 maxWalletClaimCount,
    bytes32 merkleRoot
)
    external
    returns (address dropAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenOwner`|`address`|The address of the token owner|
|`airdropTokenAddress`|`address`|The address of the airdrop token|
|`airdropAmount`|`uint256`|The amount of tokens available for airdrop|
|`expirationTimestamp`|`uint256`|The expiration timestamp of the airdrop|
|`maxWalletClaimCount`|`uint256`|The maximum number of tokens that can be claimed by a wallet if not in the whitelist|
|`merkleRoot`|`bytes32`|The merkle root of the whitelist|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dropAddress`|`address`|The address of the newly deployed airdrop contract|


### getPayoutAddress

Get the payout address for a specific category.


```solidity
function getPayoutAddress(PayoutCategory category) external view returns (address payable);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`category`|`PayoutCategory`|The category to get the payout address for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address payable`|receiver The address to receive the payout|


### getPayoutShare

Get the payout share for a specific category.


```solidity
function getPayoutShare(PayoutCategory category) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`category`|`PayoutCategory`|The category to get the payout share for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|share The share of the payout|


### updatePayout

Set the payout address for a specific category.


```solidity
function updatePayout(PayoutCategory category, address payable receiver, uint256 share) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`category`|`PayoutCategory`|The category to set the payout address for|
|`receiver`|`address payable`|The address to receive the payout|
|`share`|`uint256`|The share of the payout|


### withdraw

Withdraw the contract balance to the payout addresses.


```solidity
function withdraw() external onlyTeamMember;
```

### swapERC20s

Swap ERC20 tokens for ETH.


```solidity
function swapERC20s(address tokenAddress, uint256 amount) external onlyTeamMember;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token to swap|
|`amount`|`uint256`|The amount of tokens to swap|


### getLaunchedTokensForAddress

Get the launched tokens.


```solidity
function getLaunchedTokensForAddress(address _address) external view returns (LaunchedToken[] memory tokens);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|The address to get the tokens for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`LaunchedToken[]`|The array of launched tokens|


### getClaimableAirdropsForAddress

Get the airdrops created by a specific address.


```solidity
function getClaimableAirdropsForAddress(address _address) external view returns (ClaimableAirdrop[] memory airdrops);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_address`|`address`|The address to get the airdrops for|


## Events
### ERC20Launched

```solidity
event ERC20Launched(address indexed newTokenAddress);
```

### ClaimableAirdropCreated

```solidity
event ClaimableAirdropCreated(
    address indexed airdropAddress,
    address tokenOwner,
    address indexed airdropTokenAddress,
    uint256 indexed airdropAmount,
    uint256 expirationTimestamp,
    uint256 maxWalletClaimCount,
    bytes32 merkleRoot
);
```

### PayoutUpdated
*Event emitted when a payout address is updated.*


```solidity
event PayoutUpdated(PayoutCategory category, address receiver, uint256 share);
```

### PayoutWithdrawn
*Event emitted when a payout is withdrawn.*


```solidity
event PayoutWithdrawn(uint256 amount);
```

## Errors
### ShareToHigh
*Error emitted when the share is higher than the max share.*


```solidity
error ShareToHigh(uint256 share, uint256 maxShare);
```

### InvalidPayoutCategory
*Error emitted when the payout category is invalid.*


```solidity
error InvalidPayoutCategory(PayoutCategory category);
```

### NotTeamMember
*Error emitted when the caller is not a team member.*


```solidity
error NotTeamMember(address caller);
```

### ApprovalFailed
*Error emitted when the approval fails.*


```solidity
error ApprovalFailed();
```

## Structs
### LaunchedToken

```solidity
struct LaunchedToken {
    address tokenAddress;
    string name;
    string symbol;
    uint256 initialSupply;
    bool isBurnable;
    bool isPausable;
    bool isDeflationary;
    uint256 maxPerWallet;
    address affiliateFeeRecipient;
    address feeRecipient;
    uint256 feePercentage;
    uint256 burnPercentage;
}
```

### ClaimableAirdrop

```solidity
struct ClaimableAirdrop {
    address airdropAddress;
    address tokenOwner;
    address airdropTokenAddress;
    uint256 airdropAmount;
    uint256 expirationTimestamp;
    uint256 maxWalletClaimCount;
    bytes32 merkleRoot;
}
```

### Payout

```solidity
struct Payout {
    address payable receiver;
    uint256 share;
}
```

## Enums
### PayoutCategory

```solidity
enum PayoutCategory {
    Treasury,
    Dev,
    Legal,
    Marketing
}
```

