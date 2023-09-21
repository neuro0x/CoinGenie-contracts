// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ERC20Burnable } from "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Pausable } from "openzeppelin/token/ERC20/extensions/ERC20Pausable.sol";
import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
import { SafeMath } from "openzeppelin/utils/math/SafeMath.sol";

import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";

import { Common } from "./lib/Common.sol";
import { SafeTransfer } from "./lib/SafeTransfer.sol";

/**
 * @title CoinGenieERC20
 * @author @neuro_0x
 * @notice A robust and secure ERC20 token for the Coin Genie ecosystem
 *
 * @notice THIS ERC20 SHOULD ONLY BE DEPLOYED FROM THE COINGENIE ERC20 FACTORY
 */
contract CoinGenieERC20 is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /**
     * Private constants
     */

    /// @dev The max basis points representing 100%
    uint256 private constant _MAX_BPS = 10_000;

    /// @dev The max tax that can be applied to a transaction. The value is in ether but is handled as 5%.
    uint256 private constant _MAX_TAX = 2000; // 20%

    /// @dev The minimum amount of eth that must be added to Uniswap when trading is opened.
    uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;

    /// @dev The minimum amount of erc20 token that must be added to Uniswap when trading is opened.
    uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;

    /// @dev the royalty fee percentage taken on transfers
    uint256 private constant _TREASURY_FEE_PERCENTAGE = 50; // 0.5%;

    /// @dev the percent of eth taken when liquidity is open
    uint256 private constant _LP_ETH_FEE_PERCENTAGE = 50; // 0.5%;

    /// @dev the affiliate fee percentage taken on transfers
    uint256 private constant _AFFILIATE_FEE_PERCENTAGE = 25; // 0.25%;

    /**
     * Private immutable
     */

    /// @dev number of decimals of the token
    uint8 private immutable _tokenDecimals;

    /**
     * Private constants
     */

    /// @dev Are we currently swapping tokens for ETH?
    bool private _inSwap;

    /// @dev The whitelist of addresses that are exempt from fees
    mapping(address feePayer => bool isWhitelisted) private _feeWhitelist;

    /**
     * Public constants
     */

    /// @dev The address of the Uniswap V2 Router. The contract uses the router for liquidity provision and token swaps
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /**
     * Public immutable
     */

    /// @dev initial number of tokens which will be minted during initialization
    uint256 public immutable initialSupply;

    /// @dev address of the affiliate fee recipient
    address public immutable affiliateFeeRecipient;

    /**
     * Public
     */

    /// @dev The amount of $GENIE a person has to hold to get the discount
    uint256 public discountFeeRequiredAmount = 1_000_000 ether;

    /// @dev The address of the genie token
    address public genieToken;

    /// @dev max amount of tokens allowed per wallet
    uint256 public maxTokenAmountPerAddress;

    /// @dev max amount of tokens the contract can accrue before swapping them for ETH
    uint256 public maxTaxSwap;

    /// @dev max amount of ETH the contract can accrue before withdrawing them to the fee recipient
    uint256 public autoWithdrawThreshold;

    /// @dev features of the token
    Common.TokenConfigProperties public tokenConfig;

    /// @dev the address of the fee recipient
    address public feeRecipient;

    /// @dev address of the royalty fee recipient (Coin Genie)
    address public treasuryRecipient;

    /// @dev the fee percentage in basis points
    uint256 public feePercentage;

    /// @dev the affiliate fee percentage in basis points
    uint256 public burnPercentage;

    /// @dev The address of the LP token. The contract uses the LP token to determine if a transfer is a buy or sell
    address public uniswapV2Pair;

    /// @dev The flag for whether swapping is enabled and trading open
    bool public isSwapEnabled;

    /// @dev Modifier to prevent swapping tokens for ETH recursively
    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /// @notice Error thrown when the genie is already set.
    error GenieAlreadySet();

    /// @notice Error thrown when the provided maximum token amount is invalid.
    error InvalidMaxTokenAmount(uint256 maxPerWallet);

    /// @notice Error thrown when the new maximum token amount per address is less than or equal to the previous value.
    error MaxTokenAmountPerAddrLtPrevious();

    /// @notice Error thrown when the destination balance exceeds the maximum allowed amount.
    /// @param addr The address whose balance would exceed the limit.
    error DestBalanceExceedsMaxAllowed(address addr);

    /// @notice Error thrown when burning is not enabled.
    error BurningNotEnabled();

    /// @notice Error thrown when pausing is not enabled.
    error PausingNotEnabled();

    /// @notice Error thrown when the token is not deflationary.
    error TokenIsNotDeflationary();

    /// @notice Error thrown when an invalid tax basis point is provided.
    /// @param bps The invalid basis points for tax.
    error InvalidTaxBPS(uint256 bps);

    /// @notice Error thrown when an invalid deflation basis point is provided.
    /// @param bps The invalid basis points for deflation.
    error InvalidDeflationBPS(uint256 bps);

    /// @notice Error thrown when trading is already open.
    error TradingAlreadyOpen();

    /// @notice Error thrown when the provided ETH amount is insufficient.
    /// @param amount The provided ETH amount.
    /// @param minAmount The minimum required ETH amount.
    error InsufficientETH(uint256 amount, uint256 minAmount);

    /// @notice Error thrown when the provided token amount is insufficient.
    /// @param amount The provided token amount.
    /// @param minAmount The minimum required token amount.
    error InsufficientTokens(uint256 amount, uint256 minAmount);

    /// @notice This event is emitted when the trading is opened.
    /// @param pair The address of the LP token.
    event TradingOpened(address indexed pair);

    /// @notice This event is emitted when the maximum number of tokens allowed per wallet has been updated.
    /// @param newMaxTokenAmount The new maximum token amount per wallet.
    event MaxTokensPerWalletSet(uint256 indexed newMaxTokenAmount);

    /// @notice This event is emitted when the fee configuration of the token has been updated.
    /// @param _feeRecipient The updated fee recipient address.
    /// @param _feePercentage The updated fee percentage.
    event FeeConfigUpdated(address indexed _feeRecipient, uint256 indexed _feePercentage);

    /// @notice This event is emitted when the burn configuration of the token has been updated.
    /// @param _burnPercentage The updated burn percentage.
    event BurnConfigUpdated(uint256 indexed _burnPercentage);

    /// @notice This event is emitted when the maximum amount of tokens to swap for tax has been updated.
    /// @param maxTaxSwap The updated maximum amount of tokens to swap for tax.
    event MaxTaxSwapUpdated(uint256 indexed maxTaxSwap);

    /// @notice This event is emitted when the auto withdraw threshold has been updated.
    /// @param threshold The updated auto withdraw threshold.
    event AutoWithdrawThresholdUpdated(uint256 indexed threshold);

    /**
     * @dev Initializes the contract with the provided parameters
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param initialSupplyToSet The initial supply of the token
     * @param tokenOwner The owner of the token
     * @param customConfigProps Represents the features of the token
     * @param maxPerWallet The max amount of tokens per wallet
     * @param maxToSwapForTax The max amount of tokens to swap for tax
     * @param _affilateFeeRecipient The address of the affiliate fee recipient
     * @param _feeRecipient The address of the fee recipient
     * @param _feePercentage The fee percentage in basis points
     * @param _burnPercentage The burn percentage in basis points
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupplyToSet,
        address tokenOwner,
        Common.TokenConfigProperties memory customConfigProps,
        uint256 maxPerWallet,
        uint256 maxToSwapForTax,
        uint256 _autoWithdrawThreshold,
        address _affilateFeeRecipient,
        address _feeRecipient,
        uint256 _feePercentage,
        uint256 _burnPercentage
    )
        ERC20(name_, symbol_)
    {
        SafeTransfer.validateAddress(tokenOwner);
        initialSupply = initialSupplyToSet;
        _tokenDecimals = 18;
        affiliateFeeRecipient = _affilateFeeRecipient;

        if (_feePercentage > _MAX_TAX) {
            revert InvalidTaxBPS(_feePercentage);
        }

        if (customConfigProps.isDeflationary) {
            if (_burnPercentage > _MAX_TAX) {
                revert InvalidDeflationBPS(_burnPercentage);
            }

            burnPercentage = _burnPercentage;
        }

        tokenConfig = customConfigProps;
        maxTokenAmountPerAddress = maxPerWallet;
        maxTaxSwap = maxToSwapForTax;
        autoWithdrawThreshold = _autoWithdrawThreshold;

        SafeTransfer.validateAddress(_feeRecipient);
        feeRecipient = _feeRecipient;
        feePercentage = _feePercentage;

        if (initialSupplyToSet != 0) {
            _mint(tokenOwner, initialSupplyToSet);
        }

        _feeWhitelist[address(this)] = true;
        _feeWhitelist[tokenOwner] = true;
        _feeWhitelist[feeRecipient] = true;
        _feeWhitelist[treasuryRecipient] = true;

        if (affiliateFeeRecipient != address(0)) {
            _feeWhitelist[affiliateFeeRecipient] = true;
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    /**
     * @return true if the token is pausable
     */
    function isPausable() public view returns (bool) {
        return tokenConfig.isPausable;
    }

    /**
     * @return true if the token is burnable
     */
    function isBurnable() public view returns (bool) {
        return tokenConfig.isBurnable;
    }

    /**
     * @return true if the feePayer is whitelisted
     */
    function isWhitelisted(address feePayer) public view returns (bool) {
        return _feeWhitelist[feePayer];
    }

    /**
     * @return number of decimals for the token
     */
    function decimals() public view virtual override returns (uint8) {
        return _tokenDecimals;
    }

    /**
     * @return true if the token supports deflation
     */
    function isDeflationary() public view returns (bool) {
        return tokenConfig.isDeflationary;
    }

    /**
     * @dev Allows the owner to set the address of the coingenie
     * @param coinGenieAddress - the address of the coinGenie
     */
    function setCoinGenieTreasury(address coinGenieAddress) external {
        if (treasuryRecipient != address(0)) {
            revert GenieAlreadySet();
        }

        treasuryRecipient = coinGenieAddress;
    }

    /**
     * @dev Allows the owner to set the max amount of tokens the contract can accrue before swapping them for ETH
     * @param maxTax - the new max amount of tokens to swap for tax
     */
    function setMaxTaxSwap(uint256 maxTax) external onlyOwner {
        maxTaxSwap = maxTax;
        emit MaxTaxSwapUpdated(maxTax);
    }

    /**
     * @dev Allows the owner to set the max amount of tokens the contract can accrue before swapping them for ETH
     * @param threshold - the new max amount of tokens to swap for tax
     */
    function setAutoWithdrawThreshold(uint256 threshold) external onlyOwner {
        autoWithdrawThreshold = threshold;
        emit AutoWithdrawThresholdUpdated(threshold);
    }

    /**
     * @dev Allows the owner to set a max amount of tokens per wallet
     * @param newMaxTokenAmount - the new max amount of tokens per wallet
     *
     * @notice only callable by the owner
     * @notice only callable if the token is not paused
     * @notice only callable if the token supports max amount of tokens per wallet
     */
    function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmount) external onlyOwner whenNotPaused {
        if (newMaxTokenAmount <= maxTokenAmountPerAddress) {
            revert MaxTokenAmountPerAddrLtPrevious();
        }

        maxTokenAmountPerAddress = newMaxTokenAmount;
        emit MaxTokensPerWalletSet(newMaxTokenAmount);
    }

    /**
     * @dev Allows the owner to set the tax config
     * @param _feeRecipient - the new feeRecipient
     * @param _feePercentage - the new feePercentage
     *
     * @notice only callable by the owner
     * @notice only callable if the token is not paused
     * @notice only callable if the feePercentage is not greater than the max tax
     */
    function setTaxConfig(address _feeRecipient, uint256 _feePercentage) external onlyOwner whenNotPaused {
        if (_feePercentage > _MAX_TAX) {
            revert InvalidTaxBPS(_feePercentage);
        }

        feePercentage = _feePercentage;

        SafeTransfer.validateAddress(_feeRecipient);
        _feeWhitelist[feeRecipient] = false;
        feeRecipient = _feeRecipient;
        _feeWhitelist[feeRecipient] = true;

        emit FeeConfigUpdated(_feeRecipient, _feePercentage);
    }

    /**
     * @dev Allows the owner to set the deflation config
     * @param _burnPercentage - the new burnPercentage
     *
     * @notice only callable by the owner
     * @notice only callable if the token is not paused
     * @notice only callable if the token supports deflation
     * @notice only callable if the burnPercentage is not greater than the max allowed bps
     */
    function setDeflationConfig(uint256 _burnPercentage) external onlyOwner whenNotPaused {
        if (!isDeflationary()) {
            revert TokenIsNotDeflationary();
        }

        if (_burnPercentage > _MAX_TAX) {
            revert InvalidDeflationBPS(_burnPercentage);
        }

        burnPercentage = _burnPercentage;
        emit BurnConfigUpdated(_burnPercentage);
    }

    /**
     * @dev Allows to transfer a predefined amount of tokens to a predefined address
     * @param to - the address to transfer the tokens to
     * @param amount - the amount of tokens to transfer
     * @return true if the transfer was successful
     *
     * @notice only callable if the token is not paused
     * @notice only callable if the balance of the receiver is lower than the max amount of tokens per wallet
     * @notice checks if blacklisting is enabled and if the sender and receiver are not blacklisted
     * @notice checks if whitelisting is enabled and if the sender and receiver are whitelisted
     * @notice captures the tax during the transfer if tax is enabvled
     * @notice burns the deflationary amount during the transfer if deflation is enabled
     */
    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        address from = msg.sender;
        bool excludedFromFee = _feeWhitelist[from] || _feeWhitelist[to];

        if (isSwapEnabled && !excludedFromFee) {
            uint256 amountToTransfer = _takeFees(from, to, amount);

            return super.transfer(to, amountToTransfer);
        }

        return super.transfer(to, amount);
    }

    /**
     * @dev Allows to transfer a predefined amount of tokens from a predefined address to a predefined address
     * @param from - the address to transfer the tokens from
     * @param to - the address to transfer the tokens to
     * @param amount - the amount of tokens to transfer
     * @return true if the transfer was successful
     *
     * @notice only callable if the token is not paused
     * @notice only callable if the balance of the receiver is lower than the max amount of tokens per wallet
     * @notice checks if blacklisting is enabled and if the sender and receiver are not blacklisted
     * @notice checks if whitelisting is enabled and if the sender and receiver are whitelisted
     * @notice captures the tax during the transfer if tax is enabvled
     * @notice burns the deflationary amount during the transfer if deflation is enabled
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        bool excludedFromFee = _feeWhitelist[from] || _feeWhitelist[to];

        if (isSwapEnabled && !excludedFromFee) {
            uint256 amountToTransfer = _takeFees(from, to, amount);

            return super.transferFrom(from, to, amountToTransfer);
        }

        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Allows to burn a predefined amount of tokens
     * @param amount - the amount of tokens to burn
     *
     * @notice only callable by the owner
     * @notice only callable if the token is not paused
     * @notice only callable if the token supports burning
     */
    function burn(uint256 amount) public override onlyOwner whenNotPaused {
        if (!isBurnable()) {
            revert BurningNotEnabled();
        }

        super.burn(amount);
    }

    /**
     * @dev Allows to burn a predefined amount of tokens from a predefined address
     * @param from - the address to burn the tokens from
     * @param amount - the amount of tokens to burn
     *
     * @notice only callable by the owner
     * @notice only callable if the token is not paused
     * @notice only callable if the token supports burning
     * @notice needs Approval
     */
    function burnFrom(address from, uint256 amount) public override onlyOwner whenNotPaused {
        if (!isBurnable()) {
            revert BurningNotEnabled();
        }

        super.burnFrom(from, amount);
    }

    /**
     * @dev Allows to pause the token
     *
     * @notice only callable by the owner
     */
    function pause() external onlyOwner {
        if (!isPausable()) {
            revert PausingNotEnabled();
        }
        _pause();
    }

    /**
     * @dev Allows to unpause the token
     *
     * @notice only callable by the owner
     */
    function unpause() external onlyOwner {
        if (!isPausable()) {
            revert PausingNotEnabled();
        }
        _unpause();
    }

    /**
     * @dev Opens trading for the token by adding liquidity to Uniswap.
     * @param amountToLP The amount of tokens to add to Uniswap
     *
     * Emits a {TradingOpened} event.
     *
     * Preconditions:
     *
     * Requirements:
     *
     * `isSwapEnabled` must be false.
     * `amountToLP >= _MIN_LIQUIDITY_TOKEN`
     * `msg.value >= _MIN_LIQUIDITY_ETH`
     */
    function openTrading(uint256 amountToLP) external payable onlyOwner nonReentrant returns (IUniswapV2Pair) {
        uint256 value = msg.value;
        if (isSwapEnabled) {
            revert TradingAlreadyOpen();
        }

        if (amountToLP < _MIN_LIQUIDITY_TOKEN || balanceOf(owner()) < amountToLP) {
            revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);
        }

        if (value < _MIN_LIQUIDITY_ETH) {
            revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);
        }

        // Transfer the tokens to the contract
        transfer(address(this), amountToLP);

        // Get the ETH amount to LP and the ETH amount to treasury
        uint256 genieBalance = IERC20(genieToken).balanceOf(address(this));
        uint256 ethAmountToTreasury = value.mul(_LP_ETH_FEE_PERCENTAGE).div(_MAX_BPS);

        // If the genie balance is greater than the required amount, the fee is free
        if (genieBalance > discountFeeRequiredAmount) {
            ethAmountToTreasury = 0;
        }

        uint256 ethAmountToLP = value.sub(ethAmountToTreasury);

        // Approve the router to spend the tokens
        _approve(address(this), address(UNISWAP_V2_ROUTER), totalSupply());

        // Create the LP token
        uniswapV2Pair =
            IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());

        // Approve the router to spend the LP token
        IERC20(uniswapV2Pair).approve(address(UNISWAP_V2_ROUTER), type(uint256).max);

        // Add liquidity to Uniswap
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp
        );

        // Enable swapping
        isSwapEnabled = true;

        // Send fee to the treasury
        if (ethAmountToTreasury > 0) {
            payable(treasuryRecipient).transfer(ethAmountToTreasury);
        }

        emit TradingOpened(uniswapV2Pair);

        return IUniswapV2Pair(uniswapV2Pair);
    }

    /**
     * @dev Sets the address of the genie token
     * @param genie - the address of the genie token
     */
    function setGenie(address genie) external onlyOwner {
        if (genieToken != address(0)) {
            revert GenieAlreadySet();
        }

        genieToken = genie;
    }

    /**
     * @dev Swaps tokens for ETH if the contract balance is greater than the max amount to swap for tax. Then sends
     * the ETH to the tax wallet.
     */
    function manualSwap() external nonReentrant {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            _swapTokensForEth(_min(tokenBalance, maxTaxSwap));
        }

        // Send ETH to the tax wallet
        uint256 ethBalance = address(this).balance;
        if (ethBalance > autoWithdrawThreshold) {
            payable(owner()).transfer(ethBalance);
        }
    }

    /**
     * @dev hook called before any transfer of tokens. This includes minting and burning
     * imposed by the ERC20 standard
     * @param from - address of the sender
     * @param to - address of the recipient
     * @param amount - amount of tokens to transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC20, ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _takeFees(address from, address to, uint256 amount) private returns (uint256 _amount) {
        uint256 treasuryAmount;
        uint256 taxAmount;
        uint256 affiliateAmount;
        uint256 deflationAmount;

        if (treasuryRecipient != address(0) && _TREASURY_FEE_PERCENTAGE != 0) {
            treasuryAmount = amount.mul(_TREASURY_FEE_PERCENTAGE).div(_MAX_BPS);
        }

        if (feeRecipient != address(0) && feePercentage != 0) {
            taxAmount = amount.mul(feePercentage).div(_MAX_BPS);
        }

        if (affiliateFeeRecipient != address(0) && _AFFILIATE_FEE_PERCENTAGE != 0) {
            affiliateAmount = amount.mul(_AFFILIATE_FEE_PERCENTAGE).div(_MAX_BPS);
        }

        if (isDeflationary()) {
            deflationAmount = amount.mul(burnPercentage).div(_MAX_BPS);
        }

        _amount = amount.sub(treasuryAmount).sub(taxAmount).sub(affiliateAmount).sub(deflationAmount);
        bool exceedsMaxAmountIsBuy = from == uniswapV2Pair && to != address(UNISWAP_V2_ROUTER)
            && balanceOf(to) + _amount > maxTokenAmountPerAddress;

        if (exceedsMaxAmountIsBuy) {
            revert DestBalanceExceedsMaxAllowed(to);
        }

        if (treasuryAmount != 0) {
            _transfer(from, treasuryRecipient, treasuryAmount);
        }

        if (affiliateAmount != 0) {
            _transfer(from, affiliateFeeRecipient, affiliateAmount);
        }

        if (taxAmount != 0) {
            _transfer(from, feeRecipient, taxAmount);
        }

        if (deflationAmount != 0) {
            _burn(from, deflationAmount);
        }

        return _amount;
    }

    /**
     * @dev Swaps tokens for ETH
     * @param tokenAmount The amount of tokens to swap for ETH
     */
    function _swapTokensForEth(uint256 tokenAmount) private nonReentrant lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();
        _approve(address(this), address(UNISWAP_V2_ROUTER), tokenAmount);
        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    /**
     * @dev Returns the smallest of two numbers.
     * @param a The first number.
     * @param b The second number.
     */
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
