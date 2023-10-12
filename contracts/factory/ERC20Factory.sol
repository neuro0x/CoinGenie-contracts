// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { CoinGenieERC20 } from "../token/CoinGenieERC20.sol";
import { ICoinGenieERC20 } from "../token/ICoinGenieERC20.sol";

/**
 * @title ERC20Factory
 * @author @neuro_0x
 * @dev A factory library to deploy instances of the CoinGenieERC20 contract.
 */
contract ERC20Factory is Ownable, ReentrancyGuard {
    /// @dev The address of the genie token
    address private _genie;

    /// @dev The address of the coin genie
    address payable private _coinGenie;

    /// @dev The amount of $GENIE a person has to hold to get the discount
    uint256 private _discountFeeRequiredAmount = 100_000 ether;

    error GenieAlreadySet(address genieAddress);
    error CoinGenieAlreadySet(address coinGenieAddress);

    event GenieSet(address indexed genieAddress);
    event CoinGenieSet(address indexed coinGenieAddress);
    event DiscountFeeRequiredAmountSet(uint256 indexed amount);

    function genie() public view returns (address) {
        return _genie;
    }

    function coinGenie() public view returns (address) {
        return _coinGenie;
    }

    /**
     * @dev Creates a new instance of the CoinGenieERC20 contract
     * @param name - the name of the token
     * @param symbol - the ticker symbol of the token
     * @param totalSupply - the totalSupply of the token
     * @param feeRecipient - the address that will be the owner of the token and receive fees
     * @param affiliateFeeRecipient - the address to receive the affiliate fee
     * @param taxPercent - the percent in basis points to use as a tax
     * @param maxBuyPercent - amount of tokens allowed to be transferred in one tx as a percent of the total supply
     * @param maxWalletPercent - amount of tokens allowed to be held in one wallet as a percent of the total supply
     *
     * @return coinGenieERC20 - the CoinGenieERC20 token that was created
     */
    function launchToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address payable feeRecipient,
        address payable affiliateFeeRecipient,
        uint256 taxPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent
    )
        external
        nonReentrant
        returns (ICoinGenieERC20 coinGenieERC20)
    {
        coinGenieERC20 = new CoinGenieERC20(
            name,
            symbol,
            totalSupply,
            feeRecipient,
            _coinGenie,
            affiliateFeeRecipient,
            taxPercent,
            maxBuyPercent,
            maxWalletPercent,
            _discountFeeRequiredAmount
        );

        coinGenieERC20.setGenie(payable(_genie));
        Ownable(address(coinGenieERC20)).transferOwnership(feeRecipient);
    }

    /**
     * @dev Allows the owner to set the amount of $GENIE a person has to hold to get the discount if it has not been set
     * @param amount - the amount of $GENIE a person has to hold to get the discount
     */
    function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner {
        _discountFeeRequiredAmount = amount;
        emit DiscountFeeRequiredAmountSet(amount);
    }

    /**
     * @dev Sets the address of the genie token
     * @param genie_ - the address of the genie token
     */
    function setGenie(address genie_) external onlyOwner {
        if (_genie != address(0)) {
            revert GenieAlreadySet(_genie);
        }

        _genie = genie_;
        emit GenieSet(_genie);
    }

    /**
     * @dev Sets the address of the coin genie
     * @param coinGenie_ - the address of the coin genie
     */
    function setCoinGenie(address payable coinGenie_) external onlyOwner {
        if (_genie != address(0)) {
            revert CoinGenieAlreadySet(_coinGenie);
        }

        _coinGenie = coinGenie_;
        emit CoinGenieSet(_coinGenie);
    }
}
