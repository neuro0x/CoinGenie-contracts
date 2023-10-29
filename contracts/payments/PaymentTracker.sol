// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { IPaymentTracker } from "./IPaymentTracker.sol";

abstract contract PaymentTracker is IPaymentTracker, Ownable, ReentrancyGuard {
    uint256 private constant _MAX_BPS = 10_000;
    uint256 private constant _MAX_SHARES = 100;
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    Totals internal _totals;

    uint256 internal _affiliateFeePercent = 2000;

    mapping(address affiliate => Affiliate) internal _affiliates;
    mapping(address payee => uint256 shares) internal _shares;
    mapping(address payee => uint256 released) internal _released;

    address[] internal _payees;
    address[] internal _affiliateList;

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() external view returns (uint256) {
        return _totals.totalShares;
    }

    function totalReleased() external view returns (uint256) {
        return _totals.totalReleased;
    }

    function shares(address account) external view returns (uint256) {
        return _shares[account];
    }

    function released(address account) external view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) external view returns (address) {
        return _payees[index];
    }

    function payeeCount() external view returns (uint256) {
        return _payees.length;
    }

    function amountOwedToAllAffiliates() external view returns (uint256) {
        return _totals.totalOwedToAffiliates;
    }

    function amountOwedToAffiliate(address account) external view returns (uint256) {
        return _affiliates[account].amountOwed;
    }

    function amountPaidToAffiliate(address account) external view returns (uint256) {
        return _affiliates[account].amountPaid;
    }

    function getAffiliates() external view returns (address[] memory) {
        return _affiliateList;
    }

    function getNumberOfAffiliates() external view returns (uint256) {
        return _affiliateList.length;
    }

    function getTokensReferredByAffiliate(address account) external view returns (address[] memory) {
        return _affiliates[account].tokensReferred;
    }

    function amountEarnedByAffiliateByToken(address account, address tokenAddress) external view returns (uint256) {
        return _affiliates[account].amountEarnedByToken[tokenAddress];
    }

    function affiliateFeePercent() external view returns (uint256) {
        return _affiliateFeePercent;
    }

    function affiliateRelease(address payable account, address genie_) external nonReentrant {
        uint256 payment = _affiliates[account].amountOwed;

        if (payment == 0) {
            revert NoAmountOwedToAffiliate();
        }

        _affiliates[account].amountOwed = 0;
        _affiliates[account].amountPaid += payment;

        _totals.totalOwedToAffiliates -= payment;

        if (account == address(this)) {
            (bool success,) = account.call{ value: payment }("");
            if (!success) {
                revert PaymentFailed();
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = _UNISWAP_V2_ROUTER.WETH();
            path[1] = genie_;
            _UNISWAP_V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: payment }(
                0, path, account, block.timestamp
            );
        }

        emit PaymentReleased(account, payment);
    }

    function setAffiliatePercent(uint256 newAffiliatePercent) external onlyOwner {
        if (newAffiliatePercent > _MAX_BPS) {
            revert InvalidAffiliatePercent(newAffiliatePercent, _MAX_BPS);
        }

        _affiliateFeePercent = newAffiliatePercent;
    }

    function release(address payable account) external virtual nonReentrant {
        if (_shares[account] == 0) {
            revert ZeroSharesForAccount(account);
        }

        uint256 totalReceived = address(this).balance - _totals.totalOwedToAffiliates + _totals.totalReleased;
        uint256 payment = _pendingPayment(account, totalReceived, _released[account]);

        if (payment == 0) {
            revert AccountNotDuePayment(account);
        }

        _released[account] += payment;
        _totals.totalReleased += payment;

        (bool success,) = account.call{ value: payment }("");
        if (!success) {
            revert PaymentFailed();
        }

        emit PaymentReleased(account, payment);
    }

    function updateSplit(address[] calldata payees_, uint256[] calldata shares_) external onlyOwner {
        uint256 len = payees_.length;
        if (len != shares_.length) {
            revert PayeeShareLengthMisMatch(len, shares_.length);
        }

        if (len == 0) {
            revert NoPayees();
        }

        uint256 sumShares;
        for (uint256 i = 0; i < len;) {
            sumShares += shares_[i];

            unchecked {
                i = i + 1;
            }
        }

        if (sumShares != _MAX_SHARES) {
            revert InvalidShares(sumShares);
        }

        // Reset current shares
        uint256 currentLength = _payees.length;
        for (uint256 i = 0; i < currentLength;) {
            delete _shares[payees_[i]];

            unchecked {
                i = i + 1;
            }
        }

        // Add new shares and payees
        _payees = new address[](0);
        for (uint256 i = 0; i < len;) {
            _addPayee(payees_[i], shares_[i]);

            unchecked {
                i = i + 1;
            }
        }
    }

    function _createSplit(address[] memory payees, uint256[] memory shares_) internal {
        uint256 len = payees.length;
        if (len != shares_.length) {
            revert PayeeShareLengthMisMatch(len, shares_.length);
        }

        if (len == 0) {
            revert NoPayees();
        }

        uint256 sumShares;
        for (uint256 i = 0; i < len;) {
            sumShares += shares_[i];

            unchecked {
                i = i + 1;
            }
        }

        if (sumShares != _MAX_SHARES) {
            revert InvalidShares(sumShares);
        }

        for (uint256 i = 0; i < len;) {
            _addPayee(payees[i], shares_[i]);

            unchecked {
                i = i + 1;
            }
        }
    }

    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    )
        private
        view
        returns (uint256)
    {
        return (totalReceived * _shares[account]) / _totals.totalShares - alreadyReleased;
    }

    function _addPayee(address account, uint256 shares_) private {
        if (account == address(0)) {
            revert AccountIsZeroAddress();
        }

        if (shares_ == 0) {
            revert SharesAreZero();
        }

        if (_shares[account] != 0) {
            revert AccountAlreadyHasShares();
        }

        _payees.push(account);
        _shares[account] = shares_;
        _totals.totalShares = _totals.totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}
