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

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { Payments } from "./abstract/Payments.sol";

import { ERC20Factory } from "./factory/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "./factory/AirdropERC20ClaimableFactory.sol";

import { ICoinGenieERC20 } from "./token/ICoinGenieERC20.sol";

import { AirdropERC20Claimable } from "./AirdropERC20Claimable.sol";

/**
 * @title CoinGenie
 * @author @neuro_0x
 * @dev The orchestrator contract for the CoinGenie ecosystem.
 */
contract CoinGenie is Payments {
    uint256 private constant _MAX_BPS = 10_000;

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

    struct ClaimableAirdrop {
        address airdropAddress;
        address tokenOwner;
        address airdropTokenAddress;
        uint256 airdropAmount;
        uint256 expirationTimestamp;
        uint256 maxWalletClaimCount;
        bytes32 merkleRoot;
    }

    enum PayoutCategory {
        Treasury,
        Dev,
        Legal,
        Marketing
    }

    struct Payout {
        address payable receiver;
        uint256 share;
    }

    mapping(PayoutCategory category => Payout payout) private _payouts;

    ERC20Factory private immutable _erc20Factory;
    AirdropERC20ClaimableFactory private immutable _airdropClaimableERC20Factory;

    address[] public launchedTokens;
    address[] public createdClaimableAirdrops;

    mapping(address token => LaunchedToken launchedToken) public launchedTokenDetails;
    mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;
    mapping(address user => ClaimableAirdrop[] airdrops) public claimableAirdropCreatedBy;

    error ShareToHigh(uint256 share, uint256 maxShare);
    error InvalidPayoutCategory(PayoutCategory category);
    error NotTeamMember(address caller);
    error ApprovalFailed();

    event ERC20Launched(address indexed newTokenAddress, address indexed tokenOwner);
    event ClaimableAirdropCreated(
        address indexed airdropAddress,
        address tokenOwner,
        address indexed airdropTokenAddress,
        uint256 indexed airdropAmount,
        uint256 expirationTimestamp,
        uint256 maxWalletClaimCount,
        bytes32 merkleRoot
    );

    /**
     * @notice Construct the CoinGenie contract.
     * @param erc20FactoryAddress The address of the ERC20Factory contract
     * @param airdropClaimableERC20FactoryAddress The address of the AirdropERC20ClaimableFactory contract
     */
    constructor(address erc20FactoryAddress, address airdropClaimableERC20FactoryAddress) payable {
        _erc20Factory = ERC20Factory(erc20FactoryAddress);
        _airdropClaimableERC20Factory = AirdropERC20ClaimableFactory(airdropClaimableERC20FactoryAddress);

        address[] memory payees = new address[](4);
        uint256[] memory shares_ = new uint256[](4);

        payees[0] = 0xBe79b43B1505290DFE04294a433963dbeea736BB;
        payees[1] = 0x633Bf832Dc39C0025a7aEaa165ec91ACF02063D5;
        payees[2] = 0xbb6712A513C2d7F3E17A40d095a773c5d98574B2;
        payees[3] = 0xF14A30C09897d2C7481c5907D01Ec58Ec09555af;

        shares_[0] = 20;
        shares_[1] = 50;
        shares_[2] = 15;
        shares_[3] = 15;

        _createSplit(payees, shares_);
    }

    receive() external payable override {
        address from = _msgSender();
        // If we are receiving ETH from a Coin Genie token, then we need to send the affiliate fee
        if (launchedTokenDetails[from].tokenAddress == from) {
            address payable affiliate = launchedTokenDetails[from].affiliateFeeRecipient;
            uint256 affiliateAmount = (msg.value * _affiliateFeePercent) / _MAX_BPS;

            if (affiliateAmount != 0 && affiliate != address(0) && affiliate != address(this)) {
                _affiliatePayoutOwed += affiliateAmount;
                _amountReceivedFromAffiliate[affiliate] += msg.value;
                _amountOwedToAffiliate[affiliate] += affiliateAmount;
                _amountEarnedByAffiliateByToken[affiliate][from] += affiliateAmount;

                if (!_isTokenReferredByAffiliate[affiliate][from]) {
                    _isTokenReferredByAffiliate[affiliate][from] = true;
                    _tokensReferredByAffiliate[affiliate].push(from);
                }
            }

            emit PaymentReceived(from, msg.value);
        } else {
            emit PaymentReceived(from, msg.value);
        }
    }

    function genie() public view returns (address payable) {
        return payable(launchedTokens[0]);
    }

    /**
     * @notice Launch a new instance of the ERC20.
     * @dev This function deploys a new token contract and initializes it with provided parameters.
     * @param name - the name of the token
     * @param symbol - the ticker symbol of the token
     * @param totalSupply - the totalSupply of the token
     * @param affiliateFeeRecipient - the address to receive the affiliate fee
     * @param taxPercent - the percent in basis points to use as a tax
     * @param maxBuyPercent - amount of tokens allowed to be transferred in one tx as a percent of the total supply
     * @param maxWalletPercent - amount of tokens allowed to be held in one wallet as a percent of the total supply
     *
     * @return newToken The CoinGenieERC20 token created
     */
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
        returns (ICoinGenieERC20 newToken)
    {
        address payable feeRecipient = payable(msg.sender);
        affiliateFeeRecipient = affiliateFeeRecipient == address(0) ? payable(address(this)) : affiliateFeeRecipient;

        // Deploy the token contract
        newToken = _erc20Factory.launchToken(
            name, symbol, totalSupply, feeRecipient, affiliateFeeRecipient, taxPercent, maxBuyPercent, maxWalletPercent
        );

        // Add the token address to the array of launched token addresses
        launchedTokens.push(address(newToken));
        // Create a new LaunchedToken struct
        LaunchedToken memory launchedToken = LaunchedToken({
            index: launchedTokens.length - 1,
            tokenAddress: address(newToken),
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            feeRecipient: feeRecipient,
            affiliateFeeRecipient: affiliateFeeRecipient,
            taxPercent: taxPercent,
            maxBuyPercent: maxBuyPercent,
            maxWalletPercent: maxWalletPercent
        });

        if (tokensLaunchedBy[feeRecipient].length == 0) {
            // If the token is a new user, add the token to the array of tokens launched by the user
            tokensLaunchedBy[feeRecipient].push(launchedToken);
        } else {
            // If the token is not a new user, update the affiliateFeeRecipient to be their first ne
            launchedToken.affiliateFeeRecipient = tokensLaunchedBy[feeRecipient][0].affiliateFeeRecipient;
            tokensLaunchedBy[feeRecipient].push(launchedToken);
        }

        // Add the token details to the mapping of launched tokens
        launchedTokenDetails[address(newToken)] = launchedToken;

        // Emit the event
        emit ERC20Launched(address(newToken), msg.sender);
    }

    /**
     * @notice Launch a new instance of the CoinGenieAirdropClaimable Contract.
     * @param tokenOwner The address of the token owner
     * @param airdropTokenAddress The address of the airdrop token
     * @param airdropAmount The amount of tokens available for airdrop
     * @param expirationTimestamp The expiration timestamp of the airdrop
     * @param maxWalletClaimCount The maximum number of tokens that can be claimed by a wallet if not in the whitelist
     * @param merkleRoot The merkle root of the whitelist
     *
     * @return dropAddress The address of the newly deployed airdrop contract
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
        returns (address dropAddress)
    {
        // Deploy the airdrop contract
        AirdropERC20Claimable airdrop = _airdropClaimableERC20Factory.createClaimableAirdrop(
            tokenOwner, airdropTokenAddress, airdropAmount, expirationTimestamp, maxWalletClaimCount, merkleRoot
        );

        // Add the airdrop address to the array of created airdrops
        createdClaimableAirdrops.push(address(airdrop));

        // Add the airdrop details to the mapping of airdrops created by a specific owner
        ClaimableAirdrop memory claimableAirdrop = ClaimableAirdrop({
            airdropAddress: address(airdrop),
            tokenOwner: tokenOwner,
            airdropTokenAddress: airdropTokenAddress,
            airdropAmount: airdropAmount,
            expirationTimestamp: expirationTimestamp,
            maxWalletClaimCount: maxWalletClaimCount,
            merkleRoot: merkleRoot
        });
        claimableAirdropCreatedBy[msg.sender].push(claimableAirdrop);

        // Emit the event
        emit ClaimableAirdropCreated(
            address(airdrop),
            tokenOwner,
            airdropTokenAddress,
            airdropAmount,
            expirationTimestamp,
            maxWalletClaimCount,
            merkleRoot
        );

        return address(airdrop);
    }

    /**
     * @notice Gets the number of tokens that have been launched.
     */
    function getNumberOfLaunchedTokens() external view returns (uint256) {
        return launchedTokens.length;
    }

    /**
     * @notice Get the launched tokens.
     * @param _address The address to get the tokens for
     * @return tokens The array of launched tokens
     */
    function getLaunchedTokensForAddress(address _address) external view returns (LaunchedToken[] memory tokens) {
        return tokensLaunchedBy[_address];
    }

    /**
     * @notice Get the airdrops created by a specific address.
     * @param _address The address to get the airdrops for
     */
    function getClaimableAirdropsForAddress(address _address)
        external
        view
        returns (ClaimableAirdrop[] memory airdrops)
    {
        return claimableAirdropCreatedBy[_address];
    }
}
