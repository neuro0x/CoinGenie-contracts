// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { SafeMath } from "openzeppelin/utils/math/SafeMath.sol";

import { IUniswapV2Router02 } from "v2-periphery/interfaces/IUniswapV2Router02.sol";

import { ICoinGenieERC20 } from "./interfaces/ICoinGenieERC20.sol";

abstract contract Payments is Ownable {
    using SafeMath for uint256;

    uint256 private constant _MAX_BPS = 10_000;

    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable internal _genie;

    uint256 internal _totalShares;
    uint256 internal _totalReleased;
    uint256 internal _releaseAmount;
    uint256 internal _affiliateFeePercent = 2000;

    mapping(address payee => uint256 shares) internal _shares;
    mapping(address payee => uint256 released) internal _released;
    mapping(address affiliate => uint256 receivedFrom) internal _amountReceivedFromAffiliate;
    mapping(address affiliate => uint256 amountPaid) internal _amountPaidToAffiliate;
    mapping(address affiliate => uint256 amountOwed) internal _amountOwedToAffiliate;
    mapping(address affiliate => address[] tokensReferred) internal _tokensReferredByAffiliate;
    mapping(address affiliate => mapping(address tokenAddress => uint256 amountOwed)) internal
        _amountEarnedByAffiliateByToken;

    address[] private _payees;
    address[] private _affiliates;
    address[] private _affiliateTokens;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    error NoPayees();
    error SharesAreZero();
    error GenieAlreadySet();
    error AccountIsZeroAddress();
    error NoAmountOwedToAffiliate();
    error AccountAlreadyHasShares();
    error AccountNotDuePayment(address account);
    error ZeroSharesForAccount(address account);
    error PayeeShareLengthMisMatch(uint256 payeesLength, uint256 sharesLength);

    constructor() {
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

    receive() external payable virtual {
        /**
         * Below is a sample implementation of how this function should be overridden.
         * This is how the CoinGenie contract overrides this function.
         */
        // uint256 amountReceived = msg.value;
        // uint256 affiliateAmount = amountReceived.mul(_affiliateFeePercent).div(_MAX_BPS);
        // _releaseAmount += amountReceived.sub(affiliateAmount);

        // ICoinGenieERC20 tokenFeeIsFrom = ICoinGenieERC20(payable(msg.sender));
        // address payable affiliate = tokenFeeIsFrom.affiliateFeeRecipient();

        // _amountReceivedFromAffiliate[affiliate] += amountReceived;
        // _amountOwedToAffiliate[affiliate] += affiliateAmount;

        // _amountEarnedByAffiliateByToken[affiliate][address(tokenFeeIsFrom)] +=
        //     amountReceived.mul(_affiliateFeePercent).div(_MAX_BPS);

        emit PaymentReceived(_msgSender(), msg.value);
    }

    function genie() public view virtual returns (address payable) {
        return _genie;
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function payeeCount() public view returns (uint256) {
        return _payees.length;
    }

    function amountOwedToAffiliate(address account) public view returns (uint256) {
        return _amountOwedToAffiliate[account];
    }

    function amountPaidToAffiliate(address account) public view returns (uint256) {
        return _amountPaidToAffiliate[account];
    }

    function getTokensOfAffiliate(address account) public view returns (address[] memory) {
        return _tokensReferredByAffiliate[account];
    }

    function amountEarnedByAffiliateByToken(address affiliate, address tokenAddress) public view returns (uint256) {
        return _amountEarnedByAffiliateByToken[affiliate][tokenAddress];
    }

    function affiliateCount() public view returns (uint256) {
        return _affiliates.length;
    }

    function affiliateRelease(address payable affiliate) external {
        uint256 amountOwed = _amountOwedToAffiliate[affiliate];

        if (amountOwed == 0) {
            revert NoAmountOwedToAffiliate();
        }

        uint256 payment = amountOwed;
        _amountOwedToAffiliate[affiliate] = 0;
        _amountPaidToAffiliate[affiliate] += payment;

        if (affiliate == address(this)) {
            affiliate.transfer(payment);
        } else {
            address[] memory path = new address[](2);
            path[0] = _UNISWAP_V2_ROUTER.WETH();
            path[1] = address(this);
            _UNISWAP_V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: payment }(
                0, path, affiliate, block.timestamp
            );
        }
    }

    function release(address payable account) public virtual {
        if (_shares[account] == 0) {
            revert ZeroSharesForAccount(account);
        }

        uint256 totalReceived = _releaseAmount + _totalReleased;
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        if (payment == 0) {
            revert AccountNotDuePayment(account);
        }

        _released[account] += payment;
        _releaseAmount -= payment;
        _totalReleased += payment;

        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

    function resetSplit(address[] memory payees, uint256[] memory shares_) external onlyOwner {
        for (uint256 i = 0; i < _payees.length; i++) {
            _released[_payees[i]] = 0;
            _shares[_payees[i]] = 0;
        }

        _totalShares = 0;
        _totalReleased = 0;

        _createSplit(payees, shares_);
    }

    function setGenie(address payable genie_) external onlyOwner {
        if (_genie != address(0)) {
            revert GenieAlreadySet();
        }

        _genie = genie_;
    }

    function _createSplit(address[] memory payees, uint256[] memory shares_) internal {
        if (payees.length != shares_.length) {
            revert PayeeShareLengthMisMatch(payees.length, shares_.length);
        }

        if (payees.length == 0) {
            revert NoPayees();
        }

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    )
        internal
        view
        returns (uint256)
    {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    function _addPayee(address account, uint256 shares_) private {
        if (account == address(0)) {
            revert AccountIsZeroAddress();
        }

        if (shares_ == 0) {
            revert SharesAreZero();
        }

        if (_shares[account] > 0) {
            revert AccountAlreadyHasShares();
        }

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
