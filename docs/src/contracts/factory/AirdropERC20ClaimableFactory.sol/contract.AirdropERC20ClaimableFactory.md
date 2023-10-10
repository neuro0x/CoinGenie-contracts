# AirdropERC20ClaimableFactory
[Git Source](https://github.com/neuro0x/CoinGenie-contracts/blob/49359d99c10dd827532a13a800cae35d3199747a/contracts/factory/AirdropERC20ClaimableFactory.sol)

**Author:**
@neuro_0x

A factory library to deploy instances of the AirdropERC20Claimable contract.


## Functions
### createClaimableAirdrop

*Launch a new instance of the CoinGenieAirdropClaimable Contract.*


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
    returns (AirdropERC20Claimable newAirdrop);
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
|`newAirdrop`|`AirdropERC20Claimable`|The address of the newly deployed airdrop contract|


