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

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
import { SafeMath } from "openzeppelin/utils/math/SafeMath.sol";
import { IERC165 } from "openzeppelin/utils/introspection/IERC165.sol";

import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";

import { ICoinGenieERC20 } from "./interfaces/ICoinGenieERC20.sol";
import { SafeTransfer } from "./lib/SafeTransfer.sol";

import "hardhat/console.sol";

/**
 * @title CoinGenieERC20
 * @author @neuro_0x
 * @notice A robust and secure ERC20 token for the Coin Genie ecosystem. Inspired by APEX & TokenTool by Bitbond
 *
 * @notice THIS ERC20 SHOULD ONLY BE DEPLOYED FROM THE COINGENIE ERC20 FACTORY
 */
contract CoinGenieERC20 is ICoinGenieERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

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
    uint256 private constant _MIN_MAX_PER_WALLET = 1 ether;
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

    error GenieAlreadySet();
    error ApproveFromZeroAddress();
    error BurnFromZeroAddress();
    error TransferFromZeroAddress();
    error TradingAlreadyOpen();
    error OnlyFeeRecipient();
    error InsufficientETH(uint256 amount, uint256 minAmount);
    error InsufficientTokens(uint256 amount, uint256 minAmount);
    error InsufficientAllowance(uint256 amount, uint256 allowance);
    error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);

    event TradingOpened(address indexed pair);

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
        uint256 discountFeeRequiredAmount_,
        address tokenOwner_
    ) {
        _setERC20Properties(name_, symbol_, totalSupply_);
        _setFeeRecipients(feeRecipient_, coinGenie_, affiliateFeeRecipient_);
        _setFeePercentages(
            taxPercent_, deflationPercent_, maxBuyPercent_, maxWalletPercent_, discountFeeRequiredAmount_
        );
        _setWhitelist(feeRecipient_, coinGenie_, affiliateFeeRecipient_);

        _balances[tokenOwner_] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    // solhint-disable-next-line no-empty-blocks
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function manualSwap() external {
        if (_msgSender() != _feeTakers.feeRecipient) {
            revert OnlyFeeRecipient();
        }

        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            _swapTokensForEth(contractBalance);
        }

        uint256 contractEthBalance = address(this).balance;
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
        nonReentrant
        returns (address)
    {
        uint256 value = msg.value;
        address from = _msgSender();
        _openTradingChecks(amountToLP, value);

        transfer(address(this), amountToLP);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _totalSupply);

        CoinGenieERC20 genieToken = CoinGenieERC20(_genie);
        uint256 ethAmountToTreasury = value.mul(_LP_ETH_FEE_PERCENTAGE).div(_MAX_BPS);
        if (payInGenie) {
            ethAmountToTreasury = value.mul(_LP_ETH_FEE_PERCENTAGE.div(2)).div(_MAX_BPS);
            genieToken.transferFrom(from, _feeTakers.coinGenie, _feePercentages.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value.sub(ethAmountToTreasury);
        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());

        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, from, block.timestamp
        );

        ICoinGenieERC20(_uniswapV2Pair).approve(address(_UNISWAP_V2_ROUTER), type(uint256).max);

        _isSwapEnabled = true;
        _isTradingOpen = true;

        if (ethAmountToTreasury > 0) {
            console.log("-> ~ _feeTakers.coinGenie:", _feeTakers.coinGenie);
            _feeTakers.coinGenie.transfer(ethAmountToTreasury);
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
        uint256 ethAmountToTreasury = value.mul(_LP_ETH_FEE_PERCENTAGE).div(_MAX_BPS);

        if (payInGenie) {
            ethAmountToTreasury = value.mul(_LP_ETH_FEE_PERCENTAGE.div(2)).div(_MAX_BPS);
            genieToken.transferFrom(from, _feeTakers.coinGenie, _feePercentages.discountFeeRequiredAmount);
        }

        uint256 ethAmountToLP = value.sub(ethAmountToTreasury);

        ICoinGenieERC20(_uniswapV2Pair).approve(address(_UNISWAP_V2_ROUTER), type(uint256).max);
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmountToLP }(
            address(this), balanceOf(address(this)), 0, 0, from, block.timestamp
        );

        if (ethAmountToTreasury > 0) {
            _feeTakers.coinGenie.transfer(ethAmountToTreasury);
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

    function setFeeRecipient(address payable feeRecipient_) external onlyOwner {
        SafeTransfer.validateAddress(feeRecipient_);
        _feeTakers.feeRecipient = feeRecipient_;
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
        bool excludedFromFee = _whitelist[from] || _whitelist[to];
        if (_isSwapEnabled && !excludedFromFee) {
            uint256 burnAmount;
            uint256 totalFeePercent = _feePercentages.taxPercent + _COIN_GENIE_FEE;
            contractAmount += amount.mul(totalFeePercent).div(_MAX_BPS);
            toAmount = amount.sub(contractAmount);

            if (_feePercentages.deflationPercent > 0) {
                burnAmount = amount.mul(_feePercentages.deflationPercent).div(_MAX_BPS);
                toAmount -= burnAmount;
                _burn(from, burnAmount);
            }

            bool isBuy = from == _uniswapV2Pair && to != address(_UNISWAP_V2_ROUTER);
            if (isBuy) {
                _checkBuyRestrictions(to, toAmount);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool tokenTaxSwapLimitReached = contractTokenBalance
                >= (_totalSupply.mul(25).div(_MAX_BPS)).div(
                    1 - _feePercentages.taxPercent.div(_feePercentages.taxPercent + _COIN_GENIE_FEE)
                ) || contractTokenBalance >= _totalSupply.mul(50).div(_MAX_BPS);
            bool doAutoSwap = !_inSwap && to == _uniswapV2Pair && _isSwapEnabled && tokenTaxSwapLimitReached;
            if (doAutoSwap) {
                _swapTokensForEth(_min(toAmount, contractTokenBalance));

                uint256 contractEthBalance = address(this).balance;
                _sendEthToFee(contractEthBalance);
            }
        }

        if (contractAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(contractAmount);
            emit Transfer(from, address(this), contractAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(toAmount);

        emit Transfer(from, to, toAmount);
    }

    function _burn(address from, uint256 amount) private {
        if (from == address(0)) {
            revert BurnFromZeroAddress();
        }

        uint256 balanceOfFrom = balanceOf(from);
        if (amount > balanceOfFrom) {
            revert InsufficientTokens(amount, balanceOfFrom);
        }

        _balances[from] = balanceOfFrom.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(from, address(0), amount);
    }

    function _openTradingChecks(uint256 amountToLP, uint256 value) private view {
        if (_isSwapEnabled || _isTradingOpen) {
            revert TradingAlreadyOpen();
        }

        if (amountToLP < _MIN_LIQUIDITY_TOKEN || balanceOf(owner()) < amountToLP) {
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
        uint256 maxBuyAmount = _feePercentages.maxBuyPercent.mul(_totalSupply).div(_MAX_BPS);
        if (amount > maxBuyAmount) {
            revert ExceedsMaxAmount(amount, maxBuyAmount);
        }

        uint256 balaceOfToPlusAmount = balanceOf(to).add(amount);
        uint256 maxWalletAmount = _feePercentages.maxWalletPercent.mul(_totalSupply).div(_MAX_BPS);
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
        uint256 ownerFee = amount.mul(_feePercentages.taxPercent).div(_MAX_BPS);
        uint256 coinGenieFee = amount.mul(_COIN_GENIE_FEE).div(_MAX_BPS);

        _feeTakers.coinGenie.transfer(coinGenieFee);
        _feeTakers.feeRecipient.transfer(ownerFee);
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
