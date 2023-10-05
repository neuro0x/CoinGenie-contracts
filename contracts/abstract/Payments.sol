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
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ICoinGenieERC20 } from "../token/ICoinGenieERC20.sol";

/**
 * @title Payments
 * @author @neuro_0x
 * @dev This contract is used to split payments between multiple parties, and track and affiliates and their fees.
 */
abstract contract Payments is Ownable {
    using SafeMath for uint256;

    /// @dev The maximum amount of basis points
    uint256 private constant _MAX_BPS = 10_000;

    /// @dev The address of the Uniswap V2 Router
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /// @dev The address of the CoinGenie ERC20 $GENIE token
    address payable internal _genie;

    /// @dev The total amount of shares
    uint256 internal _totalShares;
    /// @dev The total amount of released payments
    uint256 internal _totalReleased;

    /// @dev The total amount of affiliate fees owed
    uint256 internal _affiliatePayoutOwed;
    /// @dev The affiliate fee percentage
    uint256 internal _affiliateFeePercent = 2000;

    /// @dev The mapping of shares for each payee
    mapping(address payee => uint256 shares) internal _shares;
    /// @dev The mapping of released payments for each payee
    mapping(address payee => uint256 released) internal _released;
    /// @dev The mapping of amount received from each affiliate
    mapping(address affiliate => uint256 receivedFrom) internal _amountReceivedFromAffiliate;
    /// @dev The mapping of amount paid to each affiliate
    mapping(address affiliate => uint256 amountPaid) internal _amountPaidToAffiliate;
    /// @dev The mapping of amount owed to each affiliate
    mapping(address affiliate => uint256 amountOwed) internal _amountOwedToAffiliate;
    /// @dev The mapping of tokens referred by each affiliate
    mapping(address affiliate => address[] tokensReferred) internal _tokensReferredByAffiliate;
    /// @dev The mapping of amount earned by each affiliate for each token
    mapping(address affiliate => mapping(address tokenAddress => uint256 amountOwed)) internal
        _amountEarnedByAffiliateByToken;

    /// @dev The array of payees
    address[] private _payees;
    /// @dev The array of affiliates
    address[] private _affiliates;
    /// @dev The array of affiliate tokens
    address[] private _affiliateTokens;

    /// @dev The event emitted when a payee is added
    /// @param account the payee account
    /// @param shares the amount of shares for the payee
    event PayeeAdded(address account, uint256 shares);
    /// @dev The event emitted when a payment is released
    /// @param to the account to release payment to
    /// @param amount the amount of payment released
    event PaymentReleased(address to, uint256 amount);
    /// @dev The event emitted when a payment is received
    /// @param from the account that sent the payment
    /// @param amount the amount of payment received
    event PaymentReceived(address from, uint256 amount);

    /// @dev The error emitted when there are no payees
    error NoPayees();
    /// @dev The error emitted when a payment fails
    error PaymentFailed();
    /// @dev The error emitted when shares are zero
    error SharesAreZero();
    /// @dev The error emitted when the genie is already set
    error GenieAlreadySet();
    /// @dev The error emitted when the account is a zero address
    error AccountIsZeroAddress();
    /// @dev The error emitted when there is no amount owed to an affiliate
    error NoAmountOwedToAffiliate();
    /// @dev The error emitted when an account already has shares
    error AccountAlreadyHasShares();
    /// @dev The error emitted when an account is not due payment
    /// @param account the account that is not due payment
    error AccountNotDuePayment(address account);
    /// @dev The error emitted when there are no shares for an account
    /// @param account the account that has no shares
    error ZeroSharesForAccount(address account);
    /// @dev The error emitted when the affiliate percent is invalid
    /// @param affiliatePercent the affiliate percent
    /// @param maxBps the maximum basis points
    error InvalidAffiliatePercent(uint256 affiliatePercent, uint256 maxBps);
    /// @dev The error emitted when the payee and shares lengths do not match
    /// @param payeesLength the length of the payees array
    /// @param sharesLength the length of the shares array
    error PayeeShareLengthMisMatch(uint256 payeesLength, uint256 sharesLength);

    /**
     * @dev Extending contract should override this function and emit this event
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @return the address of the CoinGenie ERC20 $GENIE token
     */
    function genie() public view virtual returns (address payable) {
        return _genie;
    }

    /**
     * @return the total amount of shares
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @return the total amount of released payments
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @param account the account to get the shares for
     * @return the amount of shares for an account
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @param account the account to get the released payments for
     * @return the amount of released payments for an account
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @param index the index of the payee to get
     * @return the address of the payee
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @return the number of payees
     */
    function payeeCount() public view returns (uint256) {
        return _payees.length;
    }

    /**
     * @return the total amount of affiliate fees owed
     */
    function amountOwedToAllAffiliates() public view returns (uint256) {
        return _affiliatePayoutOwed;
    }

    /**
     * @param account the affiliate account to get the amount owed to
     * @return the total amount owed to an affiliate
     */
    function amountOwedToAffiliate(address account) public view returns (uint256) {
        return _amountOwedToAffiliate[account];
    }

    /**
     * @param account the affiliate account to get the amount paid to
     * @return the total amount paid to an affiliate
     */
    function amountPaidToAffiliate(address account) public view returns (uint256) {
        return _amountPaidToAffiliate[account];
    }

    /**
     * @param account the affiliate account to get the tokens of
     * @return the array of tokens received from an affiliate
     */
    function getTokensOfAffiliate(address account) public view returns (address[] memory) {
        return _tokensReferredByAffiliate[account];
    }

    /**
     * @param account the affiliate account to get the amount earned from
     * @param tokenAddress the token address to get the amount earned from
     * @return the amount earned from an affiliate for a token
     */
    function amountEarnedByAffiliateByToken(address account, address tokenAddress) public view returns (uint256) {
        return _amountEarnedByAffiliateByToken[account][tokenAddress];
    }

    /**
     * @return the total number of affiliates
     */
    function affiliateCount() public view returns (uint256) {
        return _affiliates.length;
    }

    /**
     * @param index the index of the affiliate to get
     * @return the address of the affiliate
     */
    function affiliate(uint256 index) public view returns (address) {
        return _affiliates[index];
    }

    /**
     * @return the total number of affiliate tokens
     */
    function affiliateTokenCount() public view returns (uint256) {
        return _affiliateTokens.length;
    }

    /**
     * @param index the index of the affiliate token to get
     * @return the address of the affiliate token
     */
    function affiliateToken(uint256 index) public view returns (address) {
        return _affiliateTokens[index];
    }

    /**
     * @return the affiliate fee percent
     */
    function affiliateFeePercent() public view returns (uint256) {
        return _affiliateFeePercent;
    }

    /**
     * @param account the affiliate to release payment to
     */
    function affiliateRelease(address payable account) external {
        uint256 payment = _amountOwedToAffiliate[account];

        if (payment == 0) {
            revert NoAmountOwedToAffiliate();
        }

        _amountOwedToAffiliate[account] = 0;
        _amountPaidToAffiliate[account] += payment;

        _affiliatePayoutOwed -= payment;

        if (account == address(this)) {
            (bool success,) = account.call{ value: payment }("");
            if (!success) {
                revert PaymentFailed();
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = _UNISWAP_V2_ROUTER.WETH();
            path[1] = address(this);
            _UNISWAP_V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: payment }(
                0, path, account, block.timestamp
            );
        }
    }

    /**
     * @dev Set the affiliate fee percent
     * @param newAffiliatePercent the new affiliate percent
     */
    function setAffiliatePercent(uint256 newAffiliatePercent) external onlyOwner {
        if (newAffiliatePercent > _MAX_BPS) {
            revert InvalidAffiliatePercent(newAffiliatePercent, _MAX_BPS);
        }

        _affiliateFeePercent = newAffiliatePercent;
    }

    /**
     * @dev Pay a team member
     * @param account the account to release payment to
     */
    function release(address payable account) public virtual {
        if (_shares[account] == 0) {
            revert ZeroSharesForAccount(account);
        }

        uint256 totalReceived = address(this).balance - _affiliatePayoutOwed + _totalReleased;
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        if (payment == 0) {
            revert AccountNotDuePayment(account);
        }

        _released[account] += payment;
        _totalReleased += payment;

        (bool success,) = account.call{ value: payment }("");
        if (!success) {
            revert PaymentFailed();
        }
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Resets the split contract without resetting the affiliate payments
     * @param payees the array of payees
     * @param shares_ the array of shares
     *
     * @notice all payees should be paid before calling this function
     */
    function resetSplit(address[] memory payees, uint256[] memory shares_) external onlyOwner {
        for (uint256 i = 0; i < _payees.length; i++) {
            _released[_payees[i]] = 0;
            _shares[_payees[i]] = 0;
        }

        _totalShares = 0;
        _totalReleased = 0;

        _createSplit(payees, shares_);
    }

    /**
     * @dev Called on contract creation by the extending contract to set token address
     * @param genie_ the address of the CoinGenie ERC20 $GENIE token
     */
    function setGenie(address payable genie_) external onlyOwner {
        if (_genie != address(0)) {
            revert GenieAlreadySet();
        }

        _genie = genie_;
    }

    /**
     * @dev Called on contract creation to set the initial payees and shares
     * @param payees the array of payees
     * @param shares_ the array of shares
     */
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

    /**
     * @dev Helper function to get the pending payment for an account
     * @param account the account to get the pending payment for
     * @param totalReceived the total amount received
     * @param alreadyReleased the amount already released
     */
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

    /**
     * @dev Add a payee
     * @param account the account to add as a payee
     * @param shares_ the amount of shares for the payee
     */
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
