# CoinGenie
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/bb01504e3d629c383b1d91931fcf1abe87915011/contracts/CoinGenie.sol)

**Inherits:**
[Payments](/contracts/abstract/Payments.sol/abstract.Payments.md)

/// @title CoinGenie
/// @author @neuro_0x
/// @dev The orchestrator contract for the CoinGenie ecosystem.


## State Variables
### _UNISWAP_V2_ROUTER
*The address of the Uniswap V2 Router*


```solidity
IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
```


### _MAX_BPS
*The maximum percent in basis points that can be used as a discount*


```solidity
uint256 private constant _MAX_BPS = 10_000;
```


### _coinGenieFeePercent
*The percent in basis points to use as coin genie fee*


```solidity
uint256 private _coinGenieFeePercent = 100;
```


### _discountPercent
*The percent in basis points to use as a discount if paying in $GENIE*


```solidity
uint256 private _discountPercent = 5000;
```


### _discountFeeRequiredAmount
*The amount of $GENIE a person has to pay to get the discount*


```solidity
uint256 private _discountFeeRequiredAmount = 100_000 ether;
```


### _payouts
*A mapping of a payout category to a payout*


```solidity
mapping(PayoutCategory category => Payout payout) private _payouts;
```


### launchedTokens
*The array of launched token addresses*


```solidity
address[] public launchedTokens;
```


### users
*The array of users*


```solidity
address[] public users;
```


### createdClaimableAirdrops
*The array of created claimable airdrop addresses*


```solidity
address[] public createdClaimableAirdrops;
```


### launchedTokenDetails
*A mapping of a token address to its details*


```solidity
mapping(address token => LaunchedToken launchedToken) public launchedTokenDetails;
```


### tokensLaunchedBy
*A mapping of a user to the tokens they have launched*


```solidity
mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;
```


## Functions
### constructor

Construct the CoinGenie contract.


```solidity
constructor() payable;
```

### receive


```solidity
receive() external payable override;
```

### genie

Gets the address of the $GENIE contract


```solidity
function genie() public view returns (address payable);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address payable`|the address of the $GENIE contract|


### coinGenieFeePercent

Gets the percent in basis points to use as coin genie fee


```solidity
function coinGenieFeePercent() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the percent in basis points to use as coin genie fee|


### discountPercent

Gets the discount percent


```solidity
function discountPercent() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the discount percent|


### discountFeeRequiredAmount

Gets the discount fee required amount


```solidity
function discountFeeRequiredAmount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the discount fee required amount|


### launchToken

Launch a new instance of the ERC20.

*This function deploys a new token contract and initializes it with provided parameters.*


```solidity
function launchToken(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    address affiliateFeeRecipient,
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
|`affiliateFeeRecipient`|`address`|- the address to receive the affiliate fee|
|`taxPercent`|`uint256`|- the percent in basis points to use as a tax|
|`maxBuyPercent`|`uint256`|- amount of tokens allowed to be transferred in one tx as a percent of the total supply|
|`maxWalletPercent`|`uint256`|- amount of tokens allowed to be held in one wallet as a percent of the total supply|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newToken`|`ICoinGenieERC20`| - the CoinGenieERC20 token created|


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


### setCoinGenieFeePercent

Set the coin genie fee percent for tokens


```solidity
function setCoinGenieFeePercent(uint256 percent) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`percent`|`uint256`|The percent in basis points to use as coin genie fee|


### setDiscountPercent

*Allows the owner to set the percent in basis points to use as a discount*


```solidity
function setDiscountPercent(uint256 percent) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`percent`|`uint256`|- the percent in basis points to use as a discount|


### setDiscountFeeRequiredAmount

*Allows the owner to set the amount of $GENIE required to get the discount*


```solidity
function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|- the amount of $GENIE a person has to hold to get the discount|


### swapGenieForEth

Swaps tokens for Ether.

*Utilizes Uniswap for the token-to-ETH swap.*


```solidity
function swapGenieForEth(uint256 tokenAmount) external nonReentrant onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|The amount of tokens to swap for ETH.|


## Events
### DiscountPercentSet
Emits when the discount percent is set


```solidity
event DiscountPercentSet(uint256 indexed percent);
```

### DiscountFeeRequiredAmountSet
Emits when the discount fee required amount is set


```solidity
event DiscountFeeRequiredAmountSet(uint256 indexed amount);
```

### ERC20Launched
Emitted when a token is launched


```solidity
event ERC20Launched(address indexed newTokenAddress, address indexed tokenOwner);
```

## Errors
### ApprovalFailed
Reverts when approving a token fails


```solidity
error ApprovalFailed();
```

### NotTeamMember
Reverts when the caller is not a team member


```solidity
error NotTeamMember(address caller);
```

### ShareToHigh
Reverts when the share is too high


```solidity
error ShareToHigh(uint256 share, uint256 maxShare);
```

### InvalidPayoutCategory
Reverts when the payout category is invalid


```solidity
error InvalidPayoutCategory(PayoutCategory category);
```

### ExceedsMaxDiscountPercent
Reverts when the discount percent exceeds the max percent


```solidity
error ExceedsMaxDiscountPercent(uint256 percent, uint256 maxBps);
```

### ExceedsMaxFeePercent
Reverts when the coin genie fee percent exceeds the max percent


```solidity
error ExceedsMaxFeePercent(uint256 percent, uint256 maxBps);
```

## Structs
### LaunchedToken
*Struct to hold token details*


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

### Payout
*Payouts*


```solidity
struct Payout {
    address payable receiver;
    uint256 share;
}
```

## Enums
### PayoutCategory
*Payout categories*


```solidity
enum PayoutCategory {
    Treasury,
    Dev,
    Legal,
    Marketing
}
```

