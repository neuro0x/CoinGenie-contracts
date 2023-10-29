// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ICoinGenieERC20 } from "./ICoinGenieERC20.sol";

contract CoinGenieERC20 is ICoinGenieERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ICoinGenieERC20;

    uint8 private constant _DECIMALS = 18;
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

    CoinGenieERC20 private _genie;

    address private _uniswapV2Pair;

    bool private _isFeeSet;
    bool private _isTradingOpen;
    bool private _inSwap;
    bool private _isSwapEnabled;
    bool private _antibot;

    uint256 private _totalSupply;
    uint256 private _buyCount;

    string private _name;
    string private _symbol;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address feeRecipient_,
        address coinGenie_,
        address affiliateFeeRecipient_,
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 discountFeeRequiredAmount_,
        uint256 discountPercent_
    )
        payable
    {
        _setERC20Properties(name_, symbol_, totalSupply_);
        _setFeeRecipients(feeRecipient_, coinGenie_, affiliateFeeRecipient_);
        _setFeePercentages(taxPercent_, maxBuyPercent_, maxWalletPercent_, discountFeeRequiredAmount_, discountPercent_);
        _setWhitelist(feeRecipient_, coinGenie_, affiliateFeeRecipient_);

        _balances[feeRecipient_] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    receive() external payable { }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function feeRecipient() public view returns (address) {
        return _feeTakers.feeRecipient;
    }

    function affiliateFeeRecipient() public view returns (address) {
        return _feeTakers.affiliateFeeRecipient;
    }

    function coinGenie() public view returns (address) {
        return _feeTakers.coinGenie;
    }

    function genie() public view returns (address) {
        return address(_genie);
    }

    function isTradingOpen() public view returns (bool) {
        return _isTradingOpen;
    }

    function isSwapEnabled() public view returns (bool) {
        return _isSwapEnabled;
    }

    function taxPercent() public view returns (uint256) {
        return _feeAmounts.taxPercent;
    }

    function maxBuyPercent() public view returns (uint256) {
        return _feeAmounts.maxBuyPercent;
    }

    function maxWalletPercent() public view returns (uint256) {
        return _feeAmounts.maxWalletPercent;
    }

    function discountFeeRequiredAmount() public view returns (uint256) {
        return _feeAmounts.discountFeeRequiredAmount;
    }

    function discountPercent() public view returns (uint256) {
        return _feeAmounts.discountPercent;
    }

    function lpToken() public view returns (address) {
        return _uniswapV2Pair;
    }

    function amountEthReceived(address feeRecipient_) public view returns (uint256) {
        return _ethReceived[feeRecipient_];
    }

    function isAntiBot() public view returns (bool) {
        return _antibot;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    function manualSwap(uint256 amount) external {
        if (msg.sender != _feeTakers.feeRecipient) {
            revert Unauthorized();
        }

        uint256 contractTokenBalance = _balances[address(this)];
        if (amount > contractTokenBalance) {
            revert InsufficientTokens(amount, contractTokenBalance);
        }

        _swapTokensForEth(amount);

        uint256 contractEthBalance = address(this).balance;
        if (contractEthBalance != 0) {
            _sendEthToFee(contractEthBalance);
        }
    }

    function createPairAndAddLiquidity(
        uint256 amountToLP,
        bool payInGenie
    )
        external
        payable
        onlyOwner
        nonReentrant
        returns (address)
    {
        payable(address(this)).transfer(msg.value);

        uint256 value = address(this).balance;
        address from = _msgSender();

        _openTradingChecks(amountToLP, value);

        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _totalSupply);

        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;
        if (payInGenie) {
            ethAmountToTreasury = (ethAmountToTreasury * _feeAmounts.discountPercent) / _MAX_BPS;
            ICoinGenieERC20(_genie).safeTransferFrom(from, _feeTakers.coinGenie, _feeAmounts.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value - ethAmountToTreasury;
        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());

        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, from, block.timestamp
        );

        SafeERC20.safeIncreaseAllowance(ICoinGenieERC20(_uniswapV2Pair), address(_UNISWAP_V2_ROUTER), amountToLP);

        _isSwapEnabled = true;
        _isTradingOpen = true;

        if (ethAmountToTreasury != 0) {
            (bool success,) = _feeTakers.coinGenie.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.coinGenie);
            }
        }

        emit TradingOpened(_uniswapV2Pair);

        return _uniswapV2Pair;
    }

    function addLiquidity(uint256 amountToLP, bool payInGenie) external payable nonReentrant {
        if (!_isTradingOpen) {
            revert TradingNotOpen();
        }

        uint256 value = msg.value;
        address from = _msgSender();
        _addLiquidityChecks(amountToLP, value, from);

        uint256 currentContractBalance = _balances[address(this)];
        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), amountToLP);

        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;
        if (payInGenie) {
            ethAmountToTreasury = (ethAmountToTreasury * _feeAmounts.discountPercent) / _MAX_BPS;
            ICoinGenieERC20(_genie).safeTransferFrom(from, _feeTakers.coinGenie, _feeAmounts.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value - ethAmountToTreasury;
        SafeERC20.safeIncreaseAllowance(ICoinGenieERC20(_uniswapV2Pair), address(_UNISWAP_V2_ROUTER), amountToLP);
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), amountToLP, 0, 0, from, block.timestamp
        );

        if (ethAmountToTreasury != 0) {
            (bool success,) = _feeTakers.coinGenie.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.coinGenie);
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
            _transfer(address(this), _feeTakers.feeRecipient, newContractBalance - currentContractBalance);
        }
    }

    function removeLiquidity(uint256 amountToRemove) external nonReentrant {
        address from = _msgSender();
        ICoinGenieERC20(_uniswapV2Pair).safeTransferFrom(from, address(this), amountToRemove);
        _UNISWAP_V2_ROUTER.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this), amountToRemove, 0, 0, from, block.timestamp
        );
    }

    function setGenie(address genie_) external {
        if (address(_genie) != address(0)) {
            revert GenieAlreadySet();
        }

        _genie = CoinGenieERC20(payable(genie_));
        emit GenieSet(genie_);
    }

    function setMaxBuyPercent(uint256 maxBuyPercent_) external onlyOwner {
        if (maxBuyPercent_ > _MAX_BPS) {
            revert InvalidMaxBuyPercent(maxBuyPercent_);
        }

        _feeAmounts.maxBuyPercent = maxBuyPercent_;
        emit MaxBuyPercentSet(maxBuyPercent_);
    }

    function setMaxWalletPercent(uint256 maxWalletPercent_) external onlyOwner {
        if (maxWalletPercent_ > _MAX_BPS || maxWalletPercent_ < _MIN_WALLET_PERCENT) {
            revert InvalidMaxWalletPercent(maxWalletPercent_);
        }

        _feeAmounts.maxWalletPercent = maxWalletPercent_;
        emit MaxWalletPercentSet(maxWalletPercent_);
    }

    function setCoinGenieFeePercent(uint256 coinGenieFeePercent_) external {
        if (coinGenieFeePercent_ > _MAX_BPS) {
            revert InvalidCoinGenieFeePercent();
        }

        if (_isFeeSet) {
            revert CoinGenieFeePercentAlreadySet();
        }

        _isFeeSet = true;
        _feeAmounts.coinGenieFeePercent = coinGenieFeePercent_;
    }

    function setAntiBot(bool antibot_) external onlyOwner {
        _antibot = antibot_;
        emit AntiBotSet(antibot_);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0) || spender == address(0)) {
            revert ApproveFromZeroAddress();
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        _checkTransferRestrictions(from, to, amount);

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
            totalTaxAmount = _antibot && _buyCount > _REDUCE_TAX_AT
                ? (amount * _feeAmounts.taxPercent) / _MAX_BPS + (amount * _feeAmounts.coinGenieFeePercent) / _MAX_BPS
                : (amount * _INITIAL_TAX_PERCENTAGE) / _MAX_BPS + (amount * _feeAmounts.coinGenieFeePercent) / _MAX_BPS;
            if (!_inSwap && to == _uniswapV2Pair && _isTradingOpen && contractTokenBalance >= 0) {
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
            revert BurnFromZeroAddress();
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

    function _addLiquidityChecks(uint256 amountToLP, uint256 value, address from) private view {
        if (!_isSwapEnabled || !_isTradingOpen) {
            revert TradingNotOpen();
        }

        if (_balances[from] < amountToLP) {
            revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);
        }

        if (value < _MIN_LIQUIDITY_ETH) {
            revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);
        }
    }

    function _openTradingChecks(uint256 amountToLP, uint256 value) private view {
        if (_isSwapEnabled || _isTradingOpen) {
            revert TradingAlreadyOpen();
        }

        if (amountToLP < _MIN_LIQUIDITY_TOKEN || _balances[owner()] < amountToLP) {
            revert InsufficientTokens(amountToLP, _MIN_LIQUIDITY_TOKEN);
        }

        if (value < _MIN_LIQUIDITY_ETH) {
            revert InsufficientETH(value, _MIN_LIQUIDITY_ETH);
        }
    }

    function _checkTransferRestrictions(address from, address to, uint256 amount) private pure {
        if (from == address(0) || to == address(0)) {
            revert TransferFromZeroAddress();
        }

        if (amount == 0) {
            revert InsufficientTokens(amount, 0);
        }
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
        uint256 feeRecipientShare = (amount * tax) / (tax + _feeAmounts.coinGenieFeePercent);
        uint256 coinGenieShare = amount - feeRecipientShare;

        address _coinGenie = _feeTakers.coinGenie;
        (bool successCoinGenie,) = _coinGenie.call{ value: coinGenieShare }("");
        if (!successCoinGenie) {
            revert TransferFailed(coinGenieShare, address(this), _coinGenie);
        }

        address _feeRecipient = _feeTakers.feeRecipient;
        (bool successFeeRecipient,) = _feeRecipient.call{ value: feeRecipientShare }("");
        _ethReceived[_feeRecipient] += feeRecipientShare;
        if (!successFeeRecipient) {
            revert TransferFailed(feeRecipientShare, address(this), _feeTakers.coinGenie);
        }

        emit EthSentToFee(feeRecipientShare, coinGenieShare);
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _setERC20Properties(string memory name_, string memory symbol_, uint256 totalSupply_) private {
        _name = name_;
        _symbol = symbol_;

        if (totalSupply_ < 1 ether || totalSupply_ > 100_000_000_000 ether) {
            revert InvalidTotalSupply(totalSupply_);
        }
        _totalSupply = totalSupply_;
    }

    function _setFeeRecipients(address feeRecipient_, address coinGenie_, address affiliateFeeRecipient_) private {
        _feeTakers.feeRecipient = feeRecipient_;
        _feeTakers.coinGenie = coinGenie_;

        if (affiliateFeeRecipient_ == address(0)) {
            _feeTakers.affiliateFeeRecipient = coinGenie_;
        } else {
            _feeTakers.affiliateFeeRecipient = affiliateFeeRecipient_;
        }
    }

    function _setFeePercentages(
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 discountFeeRequiredAmount_,
        uint256 discountPercent_
    )
        private
    {
        _feeAmounts.taxPercent = taxPercent_;
        _feeAmounts.maxBuyPercent = maxBuyPercent_;
        _feeAmounts.maxWalletPercent = maxWalletPercent_;
        _feeAmounts.discountFeeRequiredAmount = discountFeeRequiredAmount_;
        _feeAmounts.discountPercent = discountPercent_;
    }

    function _setWhitelist(address feeRecipient_, address coinGenie_, address affiliateFeeRecipient_) private {
        _whitelist[feeRecipient_] = true;
        _whitelist[coinGenie_] = true;
        _whitelist[affiliateFeeRecipient_] = true;
        _whitelist[address(this)] = true;
    }
}
