// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { TokenTracker } from "./abstract/TokenTracker.sol";
import { PaymentTracker } from "./abstract/PaymentTracker.sol";

import { ITokenFactory } from "./interfaces/ITokenFactory.sol";

contract CoinGenie is TokenTracker, PaymentTracker {
    event TaxTokenLaunched(address taxToken);
    event RaiseTokenLaunched(address raiseToken);
    event ReflectionTokenLaunched(address reflectionToken);

    uint256 private constant _MAX_BPS = 10_000;
    uint256 private _platformFee = 100; // 1%

    address private _genieToken;
    address private _tokenFactory;

    constructor(address genieToken_, address tokenFactory_) {
        _genieToken = genieToken_;
        _tokenFactory = tokenFactory_;

        address[] memory payees = new address[](4);
        uint256[] memory shares_ = new uint256[](4);

        payees[0] = 0xBe79b43B1505290DFE04294a433963dbeea736BB; // treasury
        payees[1] = 0x3fB2120fc0CD15000d2e500Efbdd9CE17356E242; // dev
        payees[2] = 0xF14A30C09897d2C7481c5907D01Ec58Ec09555af; // marketing
        payees[3] = 0xbb6712A513C2d7F3E17A40d095a773c5d98574B2; // legal

        shares_[0] = 20;
        shares_[1] = 50;
        shares_[2] = 25;
        shares_[3] = 5;

        _createSplit(payees, shares_);
    }

    receive() external payable override(PaymentTracker) {
        address from = _msgSender();
        // If we are receiving ETH from a Coin Genie token, then we need to send the affiliate fee
        if (_launchedTokenDetails[from].tokenAddress == from) {
            address affiliate = _launchedTokenDetails[from].affiliateFeeRecipient;
            uint256 affiliateAmount = (msg.value * _affiliateFeePercent) / _MAX_BPS;

            if (affiliateAmount != 0 && affiliate != address(0) && affiliate != address(this)) {
                _totals.totalOwedToAffiliates += affiliateAmount;
                _affiliates[affiliate].amountReceived += msg.value;
                _affiliates[affiliate].amountOwed += affiliateAmount;
                _affiliates[affiliate].amountEarnedByToken[from] += affiliateAmount;

                if (!_affiliates[affiliate].isTokenReferred[from]) {
                    _affiliates[affiliate].isTokenReferred[from] = true;

                    if (_affiliates[affiliate].tokensReferred.length == 0) {
                        _affiliateList.push(affiliate);
                    }

                    _affiliates[affiliate].tokensReferred.push(from);
                }
            }
        }

        emit PaymentReceived(from, msg.value);
    }

    function genieToken() external view returns (address) {
        return _genieToken;
    }

    function setPlatformFee(uint256 platformFee_) external {
        _platformFee = platformFee_;
    }

    function updateTokenFactory(address tokenFactory_) external {
        _tokenFactory = tokenFactory_;
    }

    function launchTaxToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 taxPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent,
        address affiliate,
        bool isAntiBot
    )
        external
        payable
        returns (address taxToken)
    {
        address tokenOwner = msg.sender;
        taxToken = ITokenFactory(_tokenFactory).createTaxToken(
            name,
            symbol,
            totalSupply,
            taxPercent,
            maxBuyPercent,
            maxWalletPercent,
            _platformFee,
            affiliate,
            tokenOwner,
            address(this),
            isAntiBot
        );

        emit TaxTokenLaunched(taxToken);
    }

    function launchReflectionToken(
        string memory name,
        string memory symbol,
        uint256 tokensTotal,
        uint256 taxPercent,
        uint256 liquidityFeePercent,
        uint256 maxTxAmount,
        uint256 maxAccumulatedTaxThreshold
    )
        external
        payable
        returns (address reflectionToken)
    {
        reflectionToken = ITokenFactory(_tokenFactory).createReflectionToken(
            name,
            symbol,
            tokensTotal,
            taxPercent,
            _platformFee,
            liquidityFeePercent,
            maxTxAmount,
            maxAccumulatedTaxThreshold,
            msg.sender,
            address(this)
        );

        emit ReflectionTokenLaunched(reflectionToken);
    }
}
