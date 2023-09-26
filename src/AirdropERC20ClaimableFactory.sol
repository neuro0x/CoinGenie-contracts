// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { AirdropERC20Claimable } from "./AirdropERC20Claimable.sol";

/*
   
            ██████                                                                                  
           ████████         █████████     ██████████     ███  ████         ███                      
            ██████        █████████████ ██████████████   ████ ██████      ████                      
              ██        ████████  ████ ██████    ██████  ████ ███████     ████                      
              ██       █████          █████        █████ ████ █████████   ████                      
              ██       █████          ████         █████ ████ ████ ██████ ████                      
             ████      █████          ████         █████ ████ ████  ██████████                      
            █████       █████         █████        █████ ████ ████    ████████                      
           ████████      █████████████ ████████████████  ████ ████     ███████                      
          ████  ████      █████████████  ████████████    ████ ████       █████                      
        █████    █████        █████          ████                                                   
      ██████      ██████                                                                            
    ██████         ███████                                                                          
  ████████          ████████           ███████████  █████████████████        ████  ████ ████████████
 ████████           █████████        █████████████  ███████████████████      ████ █████ ████████████
█████████           ██████████     ███████          █████        ████████    ████ █████ ████        
██████████         ████████████    █████            █████        █████████   ████ █████ ████        
██████████████   ██████████████    █████   ████████ ████████████ ████ ██████ ████ █████ ███████████ 
███████████████████████████████    █████   ████████ ██████████   ████  ██████████ █████ ██████████  
███████████████████████████████    ██████      ████ █████        ████    ████████ █████ ████        
 █████████████████████████████      ███████████████ ████████████ ████      ██████ █████ ████████████
  ██████████████████████████          █████████████ █████████████████       █████ █████ ████████████

 */

/**
 * @title AirdropERC20ClaimableFactory
 * @author @neuro_0x
 * @notice A factory library to deploy instances of the AirdropERC20Claimable contract.
 */
contract AirdropERC20ClaimableFactory {
    /**
     * @dev Launch a new instance of the CoinGenieAirdropClaimable Contract.
     * @param tokenOwner The address of the token owner
     * @param airdropTokenAddress The address of the airdrop token
     * @param airdropAmount The amount of tokens available for airdrop
     * @param expirationTimestamp The expiration timestamp of the airdrop
     * @param maxWalletClaimCount The maximum number of tokens that can be claimed by a wallet if not in the whitelist
     * @param merkleRoot The merkle root of the whitelist
     *
     * @return newAirdrop The address of the newly deployed airdrop contract
     */
    function createClaimableAirdrop(
        address tokenOwner,
        address airdropTokenAddress,
        uint256 airdropAmount,
        uint256 expirationTimestamp,
        uint256 maxWalletClaimCount,
        bytes32 merkleRoot
    )
        external
        returns (AirdropERC20Claimable newAirdrop)
    {
        AirdropERC20Claimable claimableAirdrop = new AirdropERC20Claimable(
            tokenOwner,
            airdropTokenAddress,
            airdropAmount,
            expirationTimestamp,
            maxWalletClaimCount,
            merkleRoot
        );

        return claimableAirdrop;
    }
}
