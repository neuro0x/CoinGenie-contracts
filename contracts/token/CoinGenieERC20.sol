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

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ICoinGenieERC20 } from "./ICoinGenieERC20.sol";

/**
 * @title CoinGenieERC20
 * @author @neuro_0x
 * @notice A robust and secure ERC20 token for the Coin Genie ecosystem. Inspired by APEX & TokenTool by Bitbond
 *
 * @notice THIS ERC20 SHOULD ONLY BE DEPLOYED FROM THE COINGENIE ERC20 FACTORY
 */
contract CoinGenieERC20 is ICoinGenieERC20, Ownable, ReentrancyGuard {
    struct FeeTakers {
        address payable feeRecipient;
        address payable coinGenie;
        address payable affiliateFeeRecipient;
    }

    struct FeePercentages {
        uint256 taxPercent;
        uint256 deflationPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
        uint256 discountFeeRequiredAmount;
    }

    uint8 private constant _DECIMALS = 18;

    uint256 private constant _MAX_BPS = 10_000;
    uint256 private constant _MAX_TAX = 2000; // 20%
    uint256 private constant _MIN_LIQUIDITY_ETH = 0.5 ether;
    uint256 private constant _MIN_LIQUIDITY_TOKEN = 1 ether;
    uint256 private constant _COIN_GENIE_FEE = 100; // 1%;
    uint256 private constant _LP_ETH_FEE_PERCENTAGE = 100; // 1%;

    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address holder => uint256 balance) private _balances;
    mapping(address holder => mapping(address spender => uint256 allowance)) private _allowances;
    mapping(address holder => bool isWhiteListed) private _whitelist;

    FeeTakers private _feeTakers;
    FeePercentages private _feePercentages;

    CoinGenieERC20 private _genie;

    address private _uniswapV2Pair;

    bool private _isTradingOpen;
    bool private _inSwap;
    bool private _isSwapEnabled;

    string private _name;
    string private _symbol;

    uint256 private _totalSupply;

    event TradingOpened(address indexed pair);

    error GenieAlreadySet();
    error ApproveFromZeroAddress();
    error BurnFromZeroAddress();
    error TransferFromZeroAddress();
    error TradingAlreadyOpen();
    error Unauthorized();
    error InsufficientETH(uint256 amount, uint256 minAmount);
    error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);
    error InsufficientTokens(uint256 amount, uint256 minAmount);
    error InsufficientAllowance(uint256 amount, uint256 allowance);
    error TransferFailed(uint256 amount, address from, address to);

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address payable feeRecipient_,
        address payable coinGenie_,
        address payable affiliateFeeRecipient_,
        uint256 taxPercent_,
        uint256 deflationPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 discountFeeRequiredAmount_
    ) {
        _setERC20Properties(name_, symbol_, totalSupply_);
        _setFeeRecipients(feeRecipient_, coinGenie_, affiliateFeeRecipient_);
        _setFeePercentages(
            taxPercent_, deflationPercent_, maxBuyPercent_, maxWalletPercent_, discountFeeRequiredAmount_
        );
        _setWhitelist(feeRecipient_, coinGenie_, affiliateFeeRecipient_);

        _balances[feeRecipient_] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    function name() public view returns (string memory) {
        return string(abi.encodePacked(_name));
    }

    function symbol() public view returns (string memory) {
        return string(abi.encodePacked(_symbol));
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function feeRecipient() public view returns (address payable) {
        return _feeTakers.feeRecipient;
    }

    function coinGenie() public view returns (address payable) {
        return _feeTakers.coinGenie;
    }

    function genie() public view returns (address payable) {
        return payable(address(_genie));
    }

    function affiliateFeeRecipient() public view returns (address payable) {
        return _feeTakers.affiliateFeeRecipient;
    }

    function isTradingOpen() public view returns (bool) {
        return _isTradingOpen;
    }

    function isSwapEnabled() public view returns (bool) {
        return _isSwapEnabled;
    }

    function isDeflationary() public view returns (bool) {
        return _feePercentages.deflationPercent > 0;
    }

    function taxPercent() public view returns (uint256) {
        return _feePercentages.taxPercent;
    }

    function deflationPercent() public view returns (uint256) {
        return _feePercentages.deflationPercent;
    }

    function maxBuyPercent() public view returns (uint256) {
        return _feePercentages.maxBuyPercent;
    }

    function maxWalletPercent() public view returns (uint256) {
        return _feePercentages.maxWalletPercent;
    }

    function discountFeeRequiredAmount() public view returns (uint256) {
        return _feePercentages.discountFeeRequiredAmount;
    }

    function lpToken() public view returns (address) {
        return _uniswapV2Pair;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        if (amount > _allowances[from][msg.sender]) {
            revert InsufficientAllowance(amount, _allowances[from][msg.sender]);
        }

        _burn(from, amount);
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

    function manualSwap() external {
        address from = _msgSender();
        if (from != _feeTakers.feeRecipient || from != owner()) {
            revert Unauthorized();
        }

        uint256 contractBalance = balanceOf(address(this));
        uint256 contractEthBalance = address(this).balance;
        if (contractBalance == 0 && contractEthBalance == 0) {
            revert TransferFailed(contractBalance, address(this), _feeTakers.feeRecipient);
        }

        if (contractBalance > 0) {
            _swapTokensForEth(contractBalance);
        }

        if (contractEthBalance > 0) {
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
        returns (address)
    {
        uint256 value = msg.value;
        address from = _msgSender();
        _openTradingChecks(amountToLP, value);

        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _totalSupply);

        CoinGenieERC20 genieToken = CoinGenieERC20(_genie);
        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;
        if (payInGenie) {
            ethAmountToTreasury = (ethAmountToTreasury * 2) / 4;
            genieToken.transferFrom(from, _feeTakers.coinGenie, _feePercentages.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value - ethAmountToTreasury;
        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());

        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, from, block.timestamp
        );

        ICoinGenieERC20(_uniswapV2Pair).approve(address(_UNISWAP_V2_ROUTER), type(uint256).max);

        _isSwapEnabled = true;
        _isTradingOpen = true;

        if (ethAmountToTreasury > 0) {
            (bool success,) = _feeTakers.coinGenie.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.coinGenie);
            }
        }

        emit TradingOpened(_uniswapV2Pair);

        return _uniswapV2Pair;
    }

    function addLiquidity(uint256 amountToLP, bool payInGenie) external payable nonReentrant {
        uint256 value = msg.value;
        address from = _msgSender();

        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _totalSupply);
        CoinGenieERC20 genieToken = CoinGenieERC20(_genie);
        uint256 ethAmountToTreasury = (value * _LP_ETH_FEE_PERCENTAGE) / _MAX_BPS;

        if (payInGenie) {
            ethAmountToTreasury = (ethAmountToTreasury * 2) / 4;
            genieToken.transferFrom(from, _feeTakers.coinGenie, _feePercentages.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value - ethAmountToTreasury;
        ICoinGenieERC20(_uniswapV2Pair).approve(address(_UNISWAP_V2_ROUTER), type(uint256).max);
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, from, block.timestamp
        );

        if (ethAmountToTreasury > 0) {
            (bool success,) = _feeTakers.coinGenie.call{ value: ethAmountToTreasury }("");
            if (!success) {
                revert TransferFailed(ethAmountToTreasury, address(this), _feeTakers.coinGenie);
            }
        }
    }

    function removeLiquidity(uint256 amountToRemove) external {
        address from = _msgSender();
        ICoinGenieERC20(_uniswapV2Pair).transferFrom(from, address(this), amountToRemove);
        _UNISWAP_V2_ROUTER.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this), amountToRemove, 0, 0, from, block.timestamp
        );
    }

    function setGenie(address payable genie_) external {
        if (address(_genie) != address(0)) {
            revert GenieAlreadySet();
        }

        _genie = CoinGenieERC20(genie_);
    }

    function setTaxPercent(uint256 taxPercent_) external onlyOwner {
        if (taxPercent_ > _MAX_TAX) {
            revert ExceedsMaxAmount(taxPercent_, _MAX_TAX);
        }

        _feePercentages.taxPercent = taxPercent_;
    }

    function setDeflationPercent(uint256 deflationPercent_) external onlyOwner {
        if (deflationPercent_ > _MAX_TAX) {
            revert ExceedsMaxAmount(deflationPercent_, _MAX_TAX);
        }

        _feePercentages.deflationPercent = deflationPercent_;
    }

    function setMaxBuyPercent(uint256 maxBuyPercent_) external onlyOwner {
        _feePercentages.maxBuyPercent = maxBuyPercent_;
    }

    function setMaxWalletPercent(uint256 maxWalletPercent_) external onlyOwner {
        _feePercentages.maxWalletPercent = maxWalletPercent_;
    }

    function setFeeRecipient(address payable feeRecipient_) external onlyOwner {
        _feeTakers.feeRecipient = feeRecipient_;
        transferOwnership(feeRecipient_);
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

        uint256 contractAmount;
        uint256 toAmount = amount;
        if (_isSwapEnabled && _whitelist[from] || _whitelist[to]) {
            uint256 _taxPercent = _feePercentages.taxPercent;
            uint256 _deflationPercent = _feePercentages.deflationPercent;
            uint256 totalFeePercent = _taxPercent + _COIN_GENIE_FEE;
            contractAmount += (amount * totalFeePercent) / _MAX_BPS;
            toAmount = amount - contractAmount;

            if (_deflationPercent > 0) {
                uint256 burnAmount = (amount * _deflationPercent) / _MAX_BPS;
                toAmount -= burnAmount;
                _burn(from, burnAmount);
            }

            if (from == _uniswapV2Pair && to != address(_UNISWAP_V2_ROUTER)) {
                _checkBuyRestrictions(to, toAmount);
            }

            uint256 contractTokenBalance = _balances[address(this)];
            if (!_inSwap && to == _uniswapV2Pair && contractTokenBalance >= (_totalSupply * 50) / _MAX_BPS) {
                _swapTokensForEth(_min(toAmount, contractTokenBalance));
                _sendEthToFee(address(this).balance);
            }
        }

        if (contractAmount > 0) {
            unchecked {
                _balances[address(this)] += contractAmount;
            }

            emit Transfer(from, address(this), contractAmount);
        }

        unchecked {
            _balances[from] -= amount;
            _balances[to] += toAmount;
        }

        emit Transfer(from, to, toAmount);
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

    function _checkBuyRestrictions(address to, uint256 amount) private view {
        uint256 maxBuyAmount = (_feePercentages.maxBuyPercent * _totalSupply) / _MAX_BPS;
        if (amount > maxBuyAmount) {
            revert ExceedsMaxAmount(amount, maxBuyAmount);
        }

        uint256 balaceOfToPlusAmount = _balances[to] + amount;
        uint256 maxWalletAmount = (_feePercentages.maxWalletPercent * _totalSupply) / _MAX_BPS;
        if (balaceOfToPlusAmount > maxWalletAmount) {
            revert ExceedsMaxAmount(balaceOfToPlusAmount, maxWalletAmount);
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
        uint256 amountToGenie = (amount * _COIN_GENIE_FEE) / _MAX_BPS;
        address payable _coinGenie = _feeTakers.coinGenie;
        (bool successCoinGenie,) = _coinGenie.call{ value: amountToGenie }("");
        if (!successCoinGenie) {
            revert TransferFailed(amountToGenie, address(this), _coinGenie);
        }

        uint256 amountToFeeRecipient = amount - amountToGenie;
        address payable _feeRecipient = _feeTakers.feeRecipient;
        (bool successFeeRecipient,) = _feeRecipient.call{ value: amountToFeeRecipient }("");
        if (!successFeeRecipient) {
            revert TransferFailed(amountToFeeRecipient, address(this), _feeTakers.coinGenie);
        }
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _setERC20Properties(string memory name_, string memory symbol_, uint256 totalSupply_) private {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
    }

    function _setFeeRecipients(
        address payable feeRecipient_,
        address payable coinGenie_,
        address payable affiliateFeeRecipient_
    )
        private
    {
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
        uint256 deflationPercent_,
        uint256 maxBuyPercent_,
        uint256 maxWalletPercent_,
        uint256 discountFeeRequiredAmount_
    )
        private
    {
        _feePercentages.taxPercent = taxPercent_;
        _feePercentages.deflationPercent = deflationPercent_;
        _feePercentages.maxBuyPercent = maxBuyPercent_;
        _feePercentages.maxWalletPercent = maxWalletPercent_;
        _feePercentages.discountFeeRequiredAmount = discountFeeRequiredAmount_;
    }

    function _setWhitelist(address feeRecipient_, address coinGenie_, address affiliateFeeRecipient_) private {
        _whitelist[feeRecipient_] = true;
        _whitelist[coinGenie_] = true;
        _whitelist[affiliateFeeRecipient_] = true;
        _whitelist[address(this)] = true;
    }
}
