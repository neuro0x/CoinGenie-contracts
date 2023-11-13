// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { IReflectionToken } from "../interfaces/IReflectionToken.sol";

contract ReflectionToken is IReflectionToken, Ownable {
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _MAX_BPS = 10_000;

    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => uint256) private _reflectionBalances;
    mapping(address => uint256) private _tokenBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tokensTotal;
    uint256 private _reflectionsTotal;
    uint256 private _tokenFeeTotal;

    uint256 private _maxTxAmount;
    uint256 private _maxAccumulatedTaxThreshold;

    uint256 private _taxPercent;
    uint256 private _previousTaxFee = _taxPercent;
    uint256 private _platformFeePercent;

    uint256 private _liquidityFeePercent;
    uint256 private _previousLiquidityFee = _liquidityFeePercent;

    string private _name;
    string private _symbol;

    address private immutable _uniswapV2Pair;
    address private _feeRecipient;
    address private _platformFeeRecipient;

    bool private _inSwapAndLiquify;
    bool private _swapAndLiquifyEnabled = true;

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 tokensTotal_,
        uint256 taxPercent_,
        uint256 platformFeePercent_,
        uint256 liquidityFeePercent_,
        uint256 maxTxAmount_,
        uint256 maxAccumulatedTaxThreshold_,
        address feeRecipient_,
        address platformFeeRecipient_
    )
        payable
    {
        address from = msg.sender;

        _setERC20Properties(name_, symbol_);
        _setFees(taxPercent_, platformFeePercent_, liquidityFeePercent_);
        _setTradeLimits(maxTxAmount_, maxAccumulatedTaxThreshold_);
        _setFeeRecipients(feeRecipient_, platformFeeRecipient_);
        _setTotals(tokensTotal_, from);

        // Create a uniswap pair for this new token
        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());

        Ownable(address(this)).transferOwnership(feeRecipient_);

        _setWhitelist(feeRecipient_, platformFeeRecipient_);

        emit Transfer(address(0), from, _tokensTotal);
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
        return _tokensTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalances[account];
        return tokenFromReflection(_reflectionBalances[account]);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        address from = msg.sender;
        _transfer(sender, recipient, amount);
        _approve(sender, from, _allowances[sender][from] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        address from = msg.sender;
        _approve(from, spender, _allowances[from][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        address from = msg.sender;
        _approve(from, spender, _allowances[from][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function totalFees() external view returns (uint256) {
        return _tokenFeeTotal;
    }

    function maxTxAmount() external view returns (uint256) {
        return _maxTxAmount;
    }

    function maxAccumulatedTaxThreshold() external view returns (uint256) {
        return _maxAccumulatedTaxThreshold;
    }

    function taxPercent() external view returns (uint256) {
        return _taxPercent;
    }

    function platformFeePercent() external view returns (uint256) {
        return _platformFeePercent;
    }

    function liquidityFeePercent() external view returns (uint256) {
        return _liquidityFeePercent;
    }

    function lpToken() external view returns (address) {
        return _uniswapV2Pair;
    }

    function feeRecipient() external view returns (address) {
        return _feeRecipient;
    }

    function platformFeeRecipient() external view returns (address) {
        return _platformFeeRecipient;
    }

    function deliver(uint256 tokenAmount) external {
        address from = msg.sender;
        require(!_isExcluded[from], "Excluded addresses cannot call this function");
        (uint256 reflectionAmount,,,,,) = _getValues(tokenAmount);
        _reflectionBalances[from] = _reflectionBalances[from] - reflectionAmount;
        _reflectionsTotal = _reflectionsTotal - reflectionAmount;
        _tokenFeeTotal = _tokenFeeTotal + tokenAmount;
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) external view returns (uint256) {
        require(tokenAmount <= _tokensTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 reflectionAmount,,,,,) = _getValues(tokenAmount);
            return reflectionAmount;
        } else {
            (, uint256 reflectionTransferAmount,,,,) = _getValues(tokenAmount);
            return reflectionTransferAmount;
        }
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _reflectionsTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return reflectionAmount / currentRate;
    }

    function excludeFromReward(address account) external onlyOwner {
        require(account != address(_UNISWAP_V2_ROUTER), "We can not exclude Uniswap router.");
        require(!_isExcluded[account], "Account is already excluded");
        if (_reflectionBalances[account] > 0) {
            _tokenBalances[account] = tokenFromReflection(_reflectionBalances[account]);
        }

        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalances[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _whitelist[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _whitelist[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxPercent = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFeePercent_) external onlyOwner {
        _liquidityFeePercent = liquidityFeePercent_;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = (_tokensTotal * maxTxPercent) / _MAX_BPS;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        _swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tokenAmount) private {
        (
            uint256 reflectionAmount,
            uint256 reflectionTransferAmount,
            uint256 reflectionFee,
            uint256 tokenTransferAmount,
            uint256 tokenFee,
            uint256 tokenLiquidity
        ) = _getValues(tokenAmount);

        _tokenBalances[sender] = _tokenBalances[sender] - tokenAmount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - reflectionAmount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + tokenTransferAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + reflectionTransferAmount;

        _takeLiquidity(tokenLiquidity);
        _reflectFee(reflectionFee, tokenFee);

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _reflectFee(uint256 reflectionFee, uint256 tokenFee) private {
        _reflectionsTotal = _reflectionsTotal - reflectionFee;
        _tokenFeeTotal = _tokenFeeTotal + tokenFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTokenValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getReflectionValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTokenValues(uint256 tokenAmount) private view returns (uint256, uint256, uint256) {
        uint256 tokenFee = _calculateTaxFee(tokenAmount);
        uint256 tokenLiquidity = _calculateLiquidityFee(tokenAmount);
        uint256 tokenTransferAmount = tokenAmount - tokenFee - tokenLiquidity;
        return (tokenTransferAmount, tokenFee, tokenLiquidity);
    }

    function _getReflectionValues(
        uint256 tokenAmount,
        uint256 tokenFee,
        uint256 tokenLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 reflectionAmount = tokenAmount * currentRate;
        uint256 reflectionFee = tokenFee * currentRate;
        uint256 reflectionLiquidity = tokenLiquidity * currentRate;
        uint256 reflectionTransferAmount = reflectionAmount - reflectionFee - reflectionLiquidity;
        return (reflectionAmount, reflectionTransferAmount, reflectionFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 reflectionSupply, uint256 tokenSupply) = _getCurrentSupply();
        return reflectionSupply / tokenSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 reflectionSupply = _reflectionsTotal;
        uint256 tokenSupply = _tokensTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectionBalances[_excluded[i]] > reflectionSupply || _tokenBalances[_excluded[i]] > tokenSupply) {
                return (_reflectionsTotal, _tokensTotal);
            }

            reflectionSupply = reflectionSupply - _reflectionBalances[_excluded[i]];
            tokenSupply = tokenSupply - _tokenBalances[_excluded[i]];
        }

        if (reflectionSupply < _reflectionsTotal / _tokensTotal) {
            return (_reflectionsTotal, _tokensTotal);
        }

        return (reflectionSupply, tokenSupply);
    }

    function _takeLiquidity(uint256 tokenLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 reflectionLiquidity = tokenLiquidity * currentRate;
        _reflectionBalances[address(this)] = _reflectionBalances[address(this)] + reflectionLiquidity;
        if (_isExcluded[address(this)]) {
            _tokenBalances[address(this)] = _tokenBalances[address(this)] + tokenLiquidity;
        }
    }

    function _calculateTaxFee(uint256 amount_) private view returns (uint256) {
        return (amount_ * _taxPercent) / _MAX_BPS;
    }

    function _calculateLiquidityFee(uint256 amount_) private view returns (uint256) {
        return (amount_ * _liquidityFeePercent) / _MAX_BPS;
    }

    function _removeAllFee() private {
        if (_taxPercent == 0 && _liquidityFeePercent == 0) return;

        _previousTaxFee = _taxPercent;
        _previousLiquidityFee = _liquidityFeePercent;

        _taxPercent = 0;
        _liquidityFeePercent = 0;
    }

    function _restoreAllFee() private {
        _taxPercent = _previousTaxFee;
        _liquidityFeePercent = _previousLiquidityFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _maxAccumulatedTaxThreshold;
        if (overMinTokenBalance && !_inSwapAndLiquify && from != _uniswapV2Pair && _swapAndLiquifyEnabled) {
            contractTokenBalance = _maxAccumulatedTaxThreshold;
            // add liquidity
            _swapAndLiquify(contractTokenBalance);
        }

        // indicates if fee should be deducted from transfer
        bool takeFee = !_whitelist[from] && !_whitelist[to];
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UNISWAP_V2_ROUTER.WETH();

        _approve(address(this), address(_UNISWAP_V2_ROUTER), tokenAmount);

        // make the swap
        _UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_UNISWAP_V2_ROUTER), tokenAmount);
        uint256 platformTaxAmount = (ethAmount * _platformFeePercent) / _MAX_BPS;
        ethAmount = ethAmount - platformTaxAmount;

        // add the liquidity
        _UNISWAP_V2_ROUTER.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _feeRecipient, // liquidity tokens are sent to the fee recipient
            block.timestamp
        );

        (bool success,) = _platformFeeRecipient.call{ value: platformTaxAmount }("");
        if (!success) {
            revert TransferFailed(platformTaxAmount, address(this), _platformFeeRecipient);
        }

        emit LiquidityAdded(tokenAmount, ethAmount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            _removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            _restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tokenAmount) private {
        (
            uint256 reflectionAmount,
            uint256 reflectionTransferAmount,
            uint256 reflectionFee,
            uint256 tokenTransferAmount,
            uint256 tokenFee,
            uint256 tokenLiquidity
        ) = _getValues(tokenAmount);

        _reflectionBalances[sender] = _reflectionBalances[sender] - reflectionAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + reflectionTransferAmount;

        _takeLiquidity(tokenLiquidity);
        _reflectFee(reflectionFee, tokenFee);

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tokenAmount) private {
        (
            uint256 reflectionAmount,
            uint256 reflectionTransferAmount,
            uint256 reflectionFee,
            uint256 tokenTransferAmount,
            uint256 tokenFee,
            uint256 tokenLiquidity
        ) = _getValues(tokenAmount);

        _reflectionBalances[sender] = _reflectionBalances[sender] - reflectionAmount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + tokenTransferAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + reflectionTransferAmount;

        _takeLiquidity(tokenLiquidity);
        _reflectFee(reflectionFee, tokenFee);

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tokenAmount) private {
        (
            uint256 reflectionAmount,
            uint256 reflectionTransferAmount,
            uint256 reflectionFee,
            uint256 tokenTransferAmount,
            uint256 tokenFee,
            uint256 tokenLiquidity
        ) = _getValues(tokenAmount);

        _tokenBalances[sender] = _tokenBalances[sender] - tokenAmount;
        _reflectionBalances[sender] = _reflectionBalances[sender] - reflectionAmount;
        _reflectionBalances[recipient] = _reflectionBalances[recipient] + reflectionTransferAmount;

        _takeLiquidity(tokenLiquidity);
        _reflectFee(reflectionFee, tokenFee);

        emit Transfer(sender, recipient, tokenTransferAmount);
    }

    function _setWhitelist(address feeRecipient_, address platformFeeRecipient_) private {
        _whitelist[feeRecipient_] = true;
        _whitelist[platformFeeRecipient_] = true;
        _whitelist[address(this)] = true;
    }

    function _setERC20Properties(string memory name_, string memory symbol_) private {
        _name = name_;
        _symbol = symbol_;
    }

    function _setFees(uint256 taxPercent_, uint256 platformFeePercent_, uint256 liquidityFeePercent_) private {
        _taxPercent = taxPercent_;
        _platformFeePercent = platformFeePercent_;
        _liquidityFeePercent = liquidityFeePercent_;
    }

    function _setTradeLimits(uint256 maxTxAmount_, uint256 maxAccumulatedTaxThreshold_) private {
        _maxTxAmount = maxTxAmount_;
        _maxAccumulatedTaxThreshold = maxAccumulatedTaxThreshold_;
    }

    function _setFeeRecipients(address feeRecipient_, address platformFeeRecipient_) private {
        _feeRecipient = feeRecipient_;
        _platformFeeRecipient = platformFeeRecipient_;
    }

    function _setTotals(uint256 tokensTotal_, address from) private {
        _tokensTotal = tokensTotal_;
        _reflectionsTotal = (MAX - (MAX % _tokensTotal));
        _reflectionBalances[from] = _reflectionsTotal;
        _tokenBalances[from] = tokensTotal_;
    }
}
