// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { Ownable } from "openzeppelin/access/Ownable.sol";

import { CoinGenieERC20 } from "./CoinGenieERC20.sol";

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
 * @title ERC20Factory
 * @author @neuro_0x
 * @dev A factory library to deploy instances of the CoinGenieERC20 contract.
 */
contract ERC20Factory is Ownable {
    /// @dev The address of the genie token
    address private _genie;

    /// @dev The amount of $GENIE a person has to hold to get the discount
    uint256 private _discountFeeRequiredAmount = 1_000_000 ether;

    /// @notice Error thrown when the genie is already set.
    error GenieAlreadySet();

    /**
     * @dev Creates a new instance of the CoinGenieERC20 contract
     * @param name - the name of the token
     * @param symbol - the ticker symbol of the token
     * @param initialSupply - the initial supply of the token
     * @param tokenOwner - the address that will be the owner of the token
     * @param isBurnable - whether or not the token is burnable
     * @param isPausable - whether or not the token is pausable
     * @param isDeflationary - whether or not the token is deflationary
     * @param maxPerWallet - the maximum amount of tokens allowed to be held by one wallet
     * @param affiliateFeeRecipient - the address to receive the affiliate fee
     * @param feeRecipient - the address to receive the tax fees
     * @param feePercentage - the percent in basis points to use as a tax
     * @param burnPercentage - the percent in basis points to burn on every tx if this token is deflationary
     * @param treasuryRecipient - the address to receive the royalty fee
     *
     * @return newToken - the CoinGenieERC20 token that was created
     */
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
        uint256 burnPercentage,
        address treasuryRecipient
    )
        external
        returns (CoinGenieERC20 newToken)
    {
        CoinGenieERC20 coinGenieERC20 = new CoinGenieERC20(
            name,
            symbol,
            initialSupply,
            tokenOwner,
            isBurnable,
            isPausable,
            isDeflationary,
            maxPerWallet,
            affiliateFeeRecipient,
            feeRecipient,
            feePercentage,
            burnPercentage
        );

        coinGenieERC20.setCoinGenieTreasury(treasuryRecipient);
        coinGenieERC20.setDiscountFeeRequiredAmount(_discountFeeRequiredAmount);
        coinGenieERC20.setGenie(_genie);

        if (tokenOwner != address(0) && tokenOwner != coinGenieERC20.owner()) {
            coinGenieERC20.transferOwnership(tokenOwner);
        }

        return coinGenieERC20;
    }

    /**
     * @dev Allows the owner to set the amount of $GENIE a person has to hold to get the discount if it has not been set
     * @param amount - the amount of $GENIE a person has to hold to get the discount
     */
    function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner {
        _discountFeeRequiredAmount = amount;
    }

    /**
     * @dev Sets the address of the genie token
     * @param genie - the address of the genie token
     */
    function setGenie(address genie) external onlyOwner {
        if (_genie != address(0)) {
            revert GenieAlreadySet();
        }

        _genie = genie;
    }
}
