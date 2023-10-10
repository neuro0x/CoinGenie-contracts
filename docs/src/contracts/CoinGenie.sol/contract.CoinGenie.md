# CoinGenie
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/58fbe1832733cdd9515df6de1fb752830a719555/contracts/CoinGenie.sol)

**Inherits:**
[Payments](/contracts/abstract/Payments.sol/abstract.Payments.md), ReentrancyGuard

**Author:**
@neuro_0x

*The orchestrator contract for the CoinGenie ecosystem.*


## State Variables
### _MAX_BPS

```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### UNISWAP_V2_ROUTER

```solidity
IUniswapV2Router02 public constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _payouts

```solidity
mapping(PayoutCategory category => Payout payout) private _payouts;
```


### _erc20Factory

```solidity
ERC20Factory private _erc20Factory;
```


### _airdropClaimableERC20Factory

```solidity
AirdropERC20ClaimableFactory private _airdropClaimableERC20Factory;
```


### launchedTokens

```solidity
address[] public launchedTokens;
```


### createdClaimableAirdrops

```solidity
address[] public createdClaimableAirdrops;
```


### launchedTokenDetails

```solidity
mapping(address token => LaunchedToken launchedToken) public launchedTokenDetails;
```


### tokensLaunchedBy

```solidity
mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;
```


### claimableAirdropCreatedBy

```solidity
mapping(address user => ClaimableAirdrop[] airdrops) public claimableAirdropCreatedBy;
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
receive() external payable override;
```

### genie


```solidity
function genie() public view override(Payments) returns (address payable);
```

### launchToken

Launch a new instance of the ERC20.

*This function deploys a new token contract and initializes it with provided parameters.*


```solidity
function launchToken(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    address payable affiliateFeeRecipient,
    uint256 taxPercent,
    uint256 maxBuyPercent,
    uint256 maxWalletPercent
)
    external
    returns (ICoinGenieERC20 newToken);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|- the name of the token|
|`symbol`|`string`|- the ticker symbol of the token|
|`totalSupply`|`uint256`|- the totalSupply of the token|
|`affiliateFeeRecipient`|`address payable`|- the address to receive the affiliate fee|
|`taxPercent`|`uint256`|- the percent in basis points to use as a tax|
|`maxBuyPercent`|`uint256`|- amount of tokens allowed to be transferred in one tx as a percent of the total supply|
|`maxWalletPercent`|`uint256`|- amount of tokens allowed to be held in one wallet as a percent of the total supply|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newToken`|`ICoinGenieERC20`|The CoinGenieERC20 token created|


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


### getNumberOfLaunchedTokens

Gets the number of tokens that have been launched.


```solidity
function getNumberOfLaunchedTokens() external view returns (uint256);
```

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
event ERC20Launched(address indexed newTokenAddress, address indexed tokenOwner);
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

## Errors
### ShareToHigh

```solidity
error ShareToHigh(uint256 share, uint256 maxShare);
```

### InvalidPayoutCategory

```solidity
error InvalidPayoutCategory(PayoutCategory category);
```

### NotTeamMember

```solidity
error NotTeamMember(address caller);
```

### ApprovalFailed

```solidity
error ApprovalFailed();
```

## Structs
### LaunchedToken

```solidity
struct LaunchedToken {
    string name;
    string symbol;
    address tokenAddress;
    address payable feeRecipient;
    address payable affiliateFeeRecipient;
    uint256 index;
    uint256 totalSupply;
    uint256 taxPercent;
    uint256 maxBuyPercent;
    uint256 maxWalletPercent;
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

