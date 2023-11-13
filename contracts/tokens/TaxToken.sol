// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ITaxToken } from "../interfaces/ITaxToken.sol";

contract TaxToken is ITaxToken, Ownable, ReentrancyGuard {
    using SafeERC20 for ITaxToken;

    uint8 private constant _DECIMALS = 18;
    uint256 private constant _MIN_TOKEN_SUPPLY = 1 ether;
    uint256 private constant _MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 private constant _MAX_BPS = 10_000;
    uint256 private constant _MAX_TAX = 500; // 5%
    uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;
    uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;
    uint256 private constant _LP_ETH_FEE_PERCENTAGE = 100; // 1%
    uint256 private constant _MIN_WALLET_PERCENT = 100; // 1%
    uint256 private constant _ETH_AUTOSWAP_AMOUNT = 0.025 ether;
    uint256 private constant _INITIAL_TAX_PERCENTAGE = 1000; // 10%
    uint256 private constant _REDUCE_TAX_AT = 10;

    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address holder => uint256 balance) private _balances;
    mapping(address holder => mapping(address spender => uint256 allowance)) private _allowances;
    mapping(address holder => bool isWhiteListed) private _whitelist;
    mapping(address feeRecipient => uint256 amountEthReceived) private _ethReceived;

    FeeTakers private _feeTakers;
    FeePercentages private _feeAmounts;
    TradeRestrictions private _tradeRestrictions;

    address private _uniswapV2Pair;

    uint256 private _totalSupply;
    uint256 private _buyCount;

    string private _name;
    string private _symbol;

    modifier lockTheSwap() {
        _tradeRestrictions.isInSwap = true;
        _;
        _tradeRestrictions.isInSwap = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 platformFeePercent_,
        address affiliate_,
        address owner_,
        address platformFeeRecipient_,
        bool isAntiBot_
    )
        payable
    {
        if (totalSupply_ < _MIN_TOKEN_SUPPLY) revert SubceedsMinAmount(totalSupply_, _MIN_TOKEN_SUPPLY);
        if (totalSupply_ > _MAX_TOKEN_SUPPLY) revert ExceedsMaxAmount(totalSupply_, _MAX_TOKEN_SUPPLY);
        if (maxBuyPercent_ > _MAX_BPS) revert ExceedsMaxAmount(maxBuyPercent_, _MAX_BPS);
        if (maxWalletPercent_ > _MAX_BPS) revert ExceedsMaxAmount(maxWalletPercent_, _MAX_BPS);
        if (maxWalletPercent_ < _MIN_WALLET_PERCENT) revert SubceedsMinAmount(maxWalletPercent_, _MIN_WALLET_PERCENT);

        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;

        _setFeeTakers(affiliate_, owner_, platformFeeRecipient_);
        _setFeeAmounts(taxPercent_, maxBuyPercent_, maxWalletPercent_, platformFeePercent_);
        _setTradeRestrictions(maxBuyPercent_, maxWalletPercent_, isAntiBot_);

        Ownable(address(this)).transferOwnership(owner_);

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    receive() external payable { }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    function feeRecipient() external view returns (address) {
        return _feeTakers.feeRecipient;
    }

    function affiliateFeeRecipient() external view returns (address) {
        return _feeTakers.affiliateFeeRecipient;
    }

    function platformFeeRecipient() external view returns (address) {
        return _feeTakers.platformFeeRecipient;
    }

    function isAntiBot() external view returns (bool) {
        return _tradeRestrictions.isAntiBot;
    }

    function isTradingOpen() external view returns (bool) {
        return _tradeRestrictions.isTradingOpen;
    }

    function taxPercent() external view returns (uint256) {
        return _feeAmounts.taxPercent;
    }

    function maxBuyPercent() external view returns (uint256) {
        return _feeAmounts.maxBuyPercent;
    }

    function maxWalletPercent() external view returns (uint256) {
        return _feeAmounts.maxWalletPercent;
    }

    function platformFeePercent() external view returns (uint256) {
        return _feeAmounts.platformFeePercent;
    }

    function lpToken() external view returns (address) {
        return _uniswapV2Pair;
    }

    function amountEthReceived(address feeRecipient_) external view returns (uint256) {
        return _ethReceived[feeRecipient_];
    }

    function manualSwap(uint256 amount) external nonReentrant {
        if (msg.sender != _feeTakers.feeRecipient) revert Unauthorized();

        uint256 contractTokenBalance = _balances[address(this)];
        if (amount > contractTokenBalance) revert InsufficientTokens(amount, contractTokenBalance);

        _swapTokensForEth(amount);

        uint256 contractEthBalance = address(this).balance;
        if (contractEthBalance != 0) {
            _sendEthToFee(contractEthBalance);
        }
    }

    function openTrading(uint256 amountToLP) external payable onlyOwner nonReentrant {
        address from = msg.sender;
        uint256 value = msg.value;

        // Revert if trading is already open
        if (_tradeRestrictions.isTradingOpen) revert BadRequest();

        // Revert if the amount to LP is less than the min liquidity token amount
        if (amountToLP < _MIN_LIQUIDITY_TOKEN) revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);

        // Revert if the amount of tokens sent is less than the balance of the caller
        if (_balances[from] < amountToLP) revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);

        // Revert if the amount of eth sent is less than the min liquidity eth amount
        if (value < _MIN_LIQUIDITY_ETH) revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);

        // Send the eth to the contract
        (bool success,) = address(this).call{ value: value }("");
        // Revert if the transfer fails
        if (!success) revert TransferFailed(value, from, address(this));

        // Send the tokens to the contract
        _balances[from] -= amountToLP;
        _balances[address(this)] += amountToLP;

        // Approve the router to spend the tokens
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _totalSupply);

        // Calculate the amount of eth to send to the platform as a fee
        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;

        // Approve the router to spend the pair
        SafeERC20.safeIncreaseAllowance(ITaxToken(_uniswapV2Pair), address(_UNISWAP_V2_ROUTER), amountToLP);

        // Create the pair
        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());

        // Add liquidity
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: value - ethAmountToTreasury }(
            address(this), _balances[address(this)], 0, 0, from, block.timestamp
        );

        // Set trading to open
        _tradeRestrictions.isTradingOpen = true;

        // Send the eth to the platform as a fee
        if (ethAmountToTreasury != 0) {
            (success,) = _feeTakers.platformFeeRecipient.call{ value: ethAmountToTreasury }("");
            if (!success) revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.platformFeeRecipient);
        }

        emit TradingOpened(_uniswapV2Pair);
    }

    function addLiquidity(uint256 amountToLP) external payable nonReentrant {
        address from = msg.sender;
        uint256 value = msg.value;
        uint256 currentContractBalance = _balances[address(this)];

        // Revert if trading is not open
        if (!_tradeRestrictions.isTradingOpen) {
            revert BadRequest();
        }

        // Revert if the amount to LP is less than the min liquidity token amount
        if (_balances[from] < amountToLP) {
            revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);
        }

        // Revert if the amount of eth sent is less than the min liquidity eth amount
        if (value < _MIN_LIQUIDITY_ETH) {
            revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);
        }

        // Send the eth to the contract
        (bool success,) = address(this).call{ value: value }("");
        // Revert if the transfer fails
        if (!success) {
            revert TransferFailed(value, from, address(this));
        }

        // Send the tokens to the contract
        _balances[owner()] -= amountToLP;
        _balances[address(this)] += amountToLP;

        // Calculate the amount of eth to send to the platform as a fee
        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;

        // Approve the router to spend the pair
        SafeERC20.safeIncreaseAllowance(ITaxToken(_uniswapV2Pair), address(_UNISWAP_V2_ROUTER), amountToLP);

        // Add liquidity
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: value - ethAmountToTreasury }(
            address(this), _balances[address(this)], 0, 0, from, block.timestamp
        );

        // Send the eth to the platform as a fee
        if (ethAmountToTreasury != 0) {
            (success,) = _feeTakers.platformFeeRecipient.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.platformFeeRecipient);
            }
        }

        // If there is any eth left in the contract, send it to the fee recipient
        uint256 ethToRefund = address(this).balance;
        if (ethToRefund != 0) {
            _sendEthToFee(ethToRefund);
        }

        // If there is any token left in the contract, send it to the fee recipient
        uint256 newContractBalance = _balances[address(this)];
        if (currentContractBalance < newContractBalance) {
            _balances[address(this)] -= newContractBalance - currentContractBalance;
            _balances[_feeTakers.feeRecipient] += newContractBalance - currentContractBalance;
        }

        emit LiquidityAdded();
    }

    function removeLiquidity(uint256 amountToRemove) external nonReentrant {
        address from = _msgSender();
        ITaxToken(_uniswapV2Pair).safeTransferFrom(from, address(this), amountToRemove);
        _UNISWAP_V2_ROUTER.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this), amountToRemove, 0, 0, from, block.timestamp
        );

        emit LiquidityRemoved();
    }

    function setAntiBot(bool isAntiBot_) external onlyOwner {
        _tradeRestrictions.isAntiBot = isAntiBot_;
        emit AntiBotSet(isAntiBot_);
    }

    function setMaxBuyPercent(uint256 maxBuyPercent_) external onlyOwner {
        if (maxBuyPercent_ > _MAX_BPS) revert ExceedsMaxAmount(maxBuyPercent_, _MAX_BPS);

        _feeAmounts.maxBuyPercent = maxBuyPercent_;
        emit MaxBuyPercentSet(maxBuyPercent_);
    }

    function setMaxWalletPercent(uint256 maxWalletPercent_) external onlyOwner {
        if (maxWalletPercent_ > _MAX_BPS) revert ExceedsMaxAmount(maxWalletPercent_, _MAX_BPS);
        if (maxWalletPercent_ < _MIN_WALLET_PERCENT) revert SubceedsMinAmount(maxWalletPercent_, _MIN_WALLET_PERCENT);

        _feeAmounts.maxWalletPercent = maxWalletPercent_;
        emit MaxWalletPercentSet(maxWalletPercent_);
    }

    function removeTradeRestrictions() external onlyOwner {
        _tradeRestrictions.isTradingOpen = true;
        _tradeRestrictions.isAntiBot = false;
        _tradeRestrictions.maxBuyPercent = _MAX_BPS;
        _tradeRestrictions.maxWalletPercent = _MAX_BPS;
        emit TradeRestrictionsRemoved();
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0) || spender == address(0)) {
            revert InvalidZeroAddress();
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (amount == 0) revert InsufficientTokens(amount, 0);
        if (to == address(0)) revert InvalidZeroAddress();
        if (from == address(0)) revert InvalidZeroAddress();

        uint256 totalTaxAmount;
        if (!_whitelist[from] && !_whitelist[to]) {
            if (from == _uniswapV2Pair && to != address(_UNISWAP_V2_ROUTER)) {
                uint256 maxBuyAmount = (_feeAmounts.maxBuyPercent * _totalSupply) / _MAX_BPS;
                if (amount > maxBuyAmount) {
                    revert ExceedsMaxAmount(amount, maxBuyAmount);
                }

                uint256 maxWalletAmount = (_feeAmounts.maxWalletPercent * _totalSupply) / _MAX_BPS;
                if (_balances[to] + amount > maxWalletAmount) {
                    revert ExceedsMaxAmount(_balances[to] + amount, maxWalletAmount);
                }

                _buyCount++;
            }

            uint256 contractTokenBalance = _balances[address(this)];
            totalTaxAmount = _tradeRestrictions.isAntiBot && _buyCount > _REDUCE_TAX_AT
                ? (amount * _feeAmounts.taxPercent) / _MAX_BPS + (amount * _feeAmounts.platformFeePercent) / _MAX_BPS
                : (amount * _INITIAL_TAX_PERCENTAGE) / _MAX_BPS + (amount * _feeAmounts.platformFeePercent) / _MAX_BPS;
            if (
                !_tradeRestrictions.isInSwap && to == _uniswapV2Pair && _tradeRestrictions.isTradingOpen
                    && contractTokenBalance >= 0
            ) {
                _swapTokensForEth(_min(amount, contractTokenBalance));

                uint256 contractEthBalance = address(this).balance;
                if (contractEthBalance >= _ETH_AUTOSWAP_AMOUNT && _buyCount > _REDUCE_TAX_AT) {
                    _sendEthToFee(contractEthBalance);
                }
            }
        }

        if (totalTaxAmount != 0) {
            _balances[address(this)] += totalTaxAmount;
            emit Transfer(from, address(this), totalTaxAmount);
        }

        uint256 amountAfterTax = amount - totalTaxAmount;
        _balances[from] -= amount;
        _balances[to] += amountAfterTax;
        emit Transfer(from, to, amountAfterTax);
    }

    function _burn(address from, uint256 amount) private {
        if (from == address(0)) {
            revert InvalidZeroAddress();
        }

        uint256 balanceOfFrom = _balances[from];
        if (amount > balanceOfFrom) {
            revert InsufficientTokens(amount, balanceOfFrom);
        }

        unchecked {
            _balances[from] -= amount;
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UNISWAP_V2_ROUTER.WETH();
        _approve(address(this), address(_UNISWAP_V2_ROUTER), tokenAmount);
        _UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _sendEthToFee(uint256 amount) private {
        uint256 tax = _feeAmounts.taxPercent;
        uint256 feeRecipientShare = (amount * tax) / (tax + _feeAmounts.platformFeePercent);
        uint256 coinGenieShare = amount - feeRecipientShare;

        address _coinGenie = _feeTakers.platformFeeRecipient;
        (bool successCoinGenie,) = _coinGenie.call{ value: coinGenieShare }("");
        if (!successCoinGenie) {
            revert TransferFailed(coinGenieShare, address(this), _coinGenie);
        }

        address _feeRecipient = _feeTakers.feeRecipient;
        (bool successFeeRecipient,) = _feeRecipient.call{ value: feeRecipientShare }("");
        _ethReceived[_feeRecipient] += feeRecipientShare;
        if (!successFeeRecipient) {
            revert TransferFailed(feeRecipientShare, address(this), _feeTakers.platformFeeRecipient);
        }

        emit EthSentToFee(feeRecipientShare, coinGenieShare);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _setTradeRestrictions(uint256 maxBuyPercent_, uint256 maxWalletPercent_, bool isAntiBot_) private {
        _tradeRestrictions.isTradingOpen = false;
        _tradeRestrictions.isAntiBot = isAntiBot_;
        _tradeRestrictions.maxBuyPercent = maxBuyPercent_;
        _tradeRestrictions.maxWalletPercent = maxWalletPercent_;
    }

    function _setFeeTakers(address affiliate_, address owner_, address platformFeeRecipient_) private {
        if (owner_ == address(0)) revert InvalidZeroAddress();
        _feeTakers.feeRecipient = owner_;
        _feeTakers.platformFeeRecipient = platformFeeRecipient_;
        _feeTakers.affiliateFeeRecipient = affiliate_;
    }

    function _setFeeAmounts(
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 platformFeePercent_
    )
        private
    {
        _feeAmounts.taxPercent = taxPercent_;
        _feeAmounts.maxBuyPercent = maxBuyPercent_;
        _feeAmounts.maxWalletPercent = maxWalletPercent_;
        _feeAmounts.platformFeePercent = platformFeePercent_;
    }
}
