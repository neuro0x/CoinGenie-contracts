// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeMath } from "openzeppelin/utils/math/SafeMath.sol";

import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "v2-periphery/interfaces/IUniswapV2Router02.sol";

import { ERC20Factory } from "./ERC20Factory.sol";
import { AirdropERC20Claimable } from "./AirdropERC20Claimable.sol";
import { AirdropERC20ClaimableFactory } from "./AirdropERC20ClaimableFactory.sol";
import { Common } from "./lib/Common.sol";
import { SafeTransfer } from "./lib/SafeTransfer.sol";

/**
 * @title CoinGenie
 * @author @neuro_0x
 * @dev The orchestrator contract for the CoinGenie ecosystem.
 */
contract CoinGenie is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    error ShareToHigh(uint256 share, uint256 maxShare);

    error InvalidPayoutCategory(PayoutCategory category);

    uint256 private constant _MAX_BPS = 10_000;

    /// @dev The address of the Uniswap V2 Router. The contract uses the router for liquidity provision and token swaps
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    struct LaunchedToken {
        address tokenAddress;
        string name;
        string symbol;
        uint256 initialSupply;
        bool isBurnable;
        bool isDeflationary;
        uint256 maxPerWallet;
        uint256 autoWithdrawThreshold;
        uint256 maxTaxSwap;
        address affiliateFeeRecipient;
        address feeRecipient;
        uint256 feePercentage;
        uint256 burnPercentage;
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

    /// @dev The threshold for the amount of tokens to swap for ETH
    uint256 public quoteThreshold = 0.1 ether;

    /// @dev A mapping of payout categories to payouts.
    mapping(PayoutCategory category => Payout payout) private _payouts;

    /// @dev Stores the address of the ERC20Factory contract.
    ERC20Factory private _erc20Factory;

    /// @dev Stores the address of the AirdropERC20Claimable contract.
    AirdropERC20ClaimableFactory private _airdropClaimableERC20Factory;

    /// @dev Stores the addresses of all airdrops launched by the contract.
    address[] public createdClaimableAirdrops;

    /// @dev A mapping of airdrops launched by a specific owner.
    mapping(address user => ClaimableAirdrop[] airdrops) public claimableAirdropCreatedBy;

    /// @dev Stores the addresses of all tokens launched by the contract.
    address[] public launchedTokens;

    /// @dev A mapping of tokens launched by a specific owner.
    mapping(address user => LaunchedToken[] tokens) public tokensLaunchedBy;

    /**
     * @notice Construct the CoinGenie contract.
     * @param erc20FactoryAddress The address of the ERC20Factory contract
     * @param airdropClaimableERC20FactoryAddress The address of the AirdropERC20ClaimableFactory contract
     */
    constructor(address erc20FactoryAddress, address airdropClaimableERC20FactoryAddress) {
        _erc20Factory = ERC20Factory(erc20FactoryAddress);
        _airdropClaimableERC20Factory = AirdropERC20ClaimableFactory(airdropClaimableERC20FactoryAddress);

        _payouts[PayoutCategory.Treasury] =
            Payout({ receiver: payable(0xBe79b43B1505290DFE04294a433963dbeea736BB), share: 2000 });
        _payouts[PayoutCategory.Dev] =
            Payout({ receiver: payable(0x633Bf832Dc39C0025a7aEaa165ec91ACF02063D5), share: 5000 });
        _payouts[PayoutCategory.Legal] =
            Payout({ receiver: payable(0xbb6712A513C2d7F3E17A40d095a773c5d98574B2), share: 1500 });
        _payouts[PayoutCategory.Marketing] =
            Payout({ receiver: payable(0xF14A30C09897d2C7481c5907D01Ec58Ec09555af), share: 1500 });
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    /**
     * @notice Launch a new instance of the ERC20.
     * @dev This function deploys a new token contract and initializes it with provided parameters.
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialSupply The initial supply of the token
     * @param tokenOwner The address that will be the owner of the token
     * @param customConfigProps A struct of configuration booleans for the token
     * @param maxPerWallet The maximum amount of tokens allowed to be held by one wallet
     * @param autoWithdrawThreshold The threshold for the amount of tokens to swap for ETH
     * @param maxTaxSwap The maximum amount of tokens allowed to be swapped at once by manual or autoswap
     * @param affiliateFeeRecipient The address to receive the affiliate fee
     * @param feeRecipient The address to receive the tax fees
     * @param feePercentage The percent in basis points to use as a tax
     * @param burnPercentage The percent in basis points to burn on every tx if this token is deflationary
     *
     * @return _tokenAddress The address of the newly deployed token contract
     */
    function launchToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address tokenOwner,
        Common.TokenConfigProperties memory customConfigProps,
        uint256 maxPerWallet,
        uint256 autoWithdrawThreshold,
        uint256 maxTaxSwap,
        address affiliateFeeRecipient,
        address feeRecipient,
        uint256 feePercentage,
        uint256 burnPercentage
    )
        external
        returns (address)
    {
        // Deploy the token contract
        IERC20 newToken = _erc20Factory.launchToken(
            name,
            symbol,
            initialSupply,
            tokenOwner,
            customConfigProps,
            maxPerWallet,
            autoWithdrawThreshold,
            maxTaxSwap,
            affiliateFeeRecipient,
            feeRecipient,
            feePercentage,
            burnPercentage,
            address(this)
        );

        address newTokenAddress = address(newToken);

        // Add the token address to the array of launched tokens
        launchedTokens.push(newTokenAddress);
        // Add the token address to the mapping of tokens launched by a specific owner
        tokensLaunchedBy[tokenOwner].push(
            LaunchedToken({
                tokenAddress: newTokenAddress,
                name: name,
                symbol: symbol,
                initialSupply: initialSupply,
                isBurnable: customConfigProps.isBurnable,
                isDeflationary: customConfigProps.isDeflationary,
                maxPerWallet: maxPerWallet,
                autoWithdrawThreshold: autoWithdrawThreshold,
                maxTaxSwap: maxTaxSwap,
                affiliateFeeRecipient: affiliateFeeRecipient,
                feeRecipient: feeRecipient,
                feePercentage: feePercentage,
                burnPercentage: burnPercentage
            })
        );

        // Emit the event
        emit ERC20Launched(newTokenAddress);

        return newTokenAddress;
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
     * @notice Get the payout address for a specific category.
     * @param category The category to get the payout address for
     * @return receiver The address to receive the payout
     */
    function getPayoutAddress(PayoutCategory category) external view returns (address payable) {
        return _payouts[category].receiver;
    }

    /**
     * @notice Get the payout share for a specific category.
     * @param category The category to get the payout share for
     * @return share The share of the payout
     */
    function getPayoutShare(PayoutCategory category) external view returns (uint256) {
        return _payouts[category].share;
    }

    /**
     * @notice Set the payout address for a specific category.
     * @param category The category to set the payout address for
     * @param receiver The address to receive the payout
     * @param share The share of the payout
     */
    function updatePayout(PayoutCategory category, address payable receiver, uint256 share) external onlyOwner {
        if (share > _payouts[category].share) {
            revert ShareToHigh(share, _payouts[category].share);
        }

        if (category > PayoutCategory.Marketing) {
            revert InvalidPayoutCategory(category);
        }

        _payouts[category] = Payout({ receiver: receiver, share: share });
    }

    /**
     * @notice Withdraw the contract balance to the payout addresses.
     */
    function withdraw() external {
        uint256 contractBalance = address(this).balance;

        uint256 treasuryShare = _payouts[PayoutCategory.Treasury].share;
        uint256 devShare = _payouts[PayoutCategory.Dev].share;
        uint256 legalShare = _payouts[PayoutCategory.Legal].share;
        uint256 marketingShare = _payouts[PayoutCategory.Marketing].share;

        uint256 treasuryAmount = contractBalance.mul(treasuryShare).div(_MAX_BPS);
        uint256 devAmount = contractBalance.mul(devShare).div(_MAX_BPS);
        uint256 legalAmount = contractBalance.mul(legalShare).div(_MAX_BPS);
        uint256 marketingAmount = contractBalance.mul(marketingShare).div(_MAX_BPS);

        SafeTransfer.safeTransferETH(_payouts[PayoutCategory.Treasury].receiver, treasuryAmount);
        SafeTransfer.safeTransferETH(_payouts[PayoutCategory.Dev].receiver, devAmount);
        SafeTransfer.safeTransferETH(_payouts[PayoutCategory.Legal].receiver, legalAmount);
        SafeTransfer.safeTransferETH(_payouts[PayoutCategory.Marketing].receiver, marketingAmount);
    }

    /**
     * @notice Swap ERC20 tokens for ETH.
     * @param tokenAddress The address of the token to swap
     * @param amount The amount of tokens to swap
     */
    function swapERC20s(address tokenAddress, address lpTokenAddress, uint256 amount) external {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(lpTokenAddress).getReserves();
        uint256 quotedAmount = UNISWAP_V2_ROUTER.quote(amount, reserve0, reserve1);

        if (quotedAmount >= quoteThreshold) {
            require(IERC20(tokenAddress).approve(address(UNISWAP_V2_ROUTER), amount), "Approval failed");

            address[] memory path = new address[](2);
            path[0] = tokenAddress;
            path[1] = UNISWAP_V2_ROUTER.WETH();

            UNISWAP_V2_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
    }

    /**
     * @notice Set the threshold for the amount of tokens to swap for ETH.
     * @param _quoteThreshold The threshold for the amount of tokens to swap for ETH
     */
    function setQuoteThreshold(uint256 _quoteThreshold) external onlyOwner {
        quoteThreshold = _quoteThreshold;
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
