// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

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
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
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
contract CoinGenie is Payments, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private constant _MAX_BPS = 10_000;

    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    struct LaunchedToken {
        address tokenAddress;
        string name;
        string symbol;
        uint256 totalSupply;
        address payable feeRecipient;
        address payable affiliateFeeRecipient;
        uint256 taxPercent;
        uint256 deflationPercent;
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

    ERC20Factory private _erc20Factory;
    AirdropERC20ClaimableFactory private _airdropClaimableERC20Factory;

    address[] public launchedTokens;
    address[] public createdClaimableAirdrops;

    mapping(address token => LaunchedToken launchedToken) public launchedTokenDetails;
    mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;
    mapping(address user => ClaimableAirdrop[] airdrops) public claimableAirdropCreatedBy;

    error ShareToHigh(uint256 share, uint256 maxShare);
    error InvalidPayoutCategory(PayoutCategory category);
    error NotTeamMember(address caller);
    error ApprovalFailed();

    event ERC20Launched(address indexed newTokenAddress);
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
     * @notice Modifier to ensure that the caller is a team member.
     */
    modifier onlyTeamMember() {
        address caller = msg.sender;
        bool isTeamMember = caller == _payouts[PayoutCategory.Treasury].receiver
            || caller == _payouts[PayoutCategory.Dev].receiver || caller == _payouts[PayoutCategory.Legal].receiver
            || caller == _payouts[PayoutCategory.Marketing].receiver;

        if (!isTeamMember) {
            revert NotTeamMember(caller);
        }

        _;
    }

    /**
     * @notice Construct the CoinGenie contract.
     * @param erc20FactoryAddress The address of the ERC20Factory contract
     * @param airdropClaimableERC20FactoryAddress The address of the AirdropERC20ClaimableFactory contract
     */
    constructor(address erc20FactoryAddress, address airdropClaimableERC20FactoryAddress) {
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
        if (launchedTokenDetails[from].tokenAddress == from) {
            address payable affiliate = launchedTokenDetails[from].affiliateFeeRecipient;
            uint256 amountReceived = msg.value;
            uint256 affiliateAmount = (amountReceived * _affiliateFeePercent) / _MAX_BPS;

            if (affiliateAmount > 0) {
                _releaseAmount += amountReceived - affiliateAmount;
                _amountReceivedFromAffiliate[affiliate] += amountReceived;
                _amountOwedToAffiliate[affiliate] += affiliateAmount;
                _amountEarnedByAffiliateByToken[affiliate][from] += affiliateAmount;
            }

            emit PaymentReceived(from, amountReceived);
        } else {
            _releaseAmount += msg.value;
            emit PaymentReceived(from, msg.value);
        }
    }

    function genie() public view override(Payments) returns (address payable) {
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
     * @param deflationPercent - the percent in basis points to use as a deflation
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
        uint256 deflationPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent
    )
        external
        returns (ICoinGenieERC20 newToken)
    {
        address payable feeRecipient = payable(msg.sender);

        // Deploy the token contract
        newToken = _erc20Factory.launchToken(
            name,
            symbol,
            totalSupply,
            feeRecipient,
            payable(address(this)),
            affiliateFeeRecipient,
            taxPercent,
            deflationPercent,
            maxBuyPercent,
            maxWalletPercent
        );

        launchedTokens.push(address(newToken));

        LaunchedToken memory launchedToken = LaunchedToken({
            tokenAddress: address(newToken),
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            feeRecipient: feeRecipient,
            affiliateFeeRecipient: affiliateFeeRecipient,
            taxPercent: taxPercent,
            deflationPercent: deflationPercent,
            maxBuyPercent: maxBuyPercent,
            maxWalletPercent: maxWalletPercent
        });

        tokensLaunchedBy[feeRecipient].push(launchedToken);
        launchedTokenDetails[address(newToken)] = launchedToken;

        // Emit the event
        emit ERC20Launched(address(newToken));

        return newToken;
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
