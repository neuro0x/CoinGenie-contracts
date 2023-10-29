// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { PaymentTracker } from "./payments/PaymentTracker.sol";

import { TokenTracker } from "./tokens/TokenTracker.sol";
import { ITokenFactory } from "./tokens/ITokenFactory.sol";
import { ICoinGenieERC20 } from "./tokens/ICoinGenieERC20.sol";

import { ILiquidityRaise } from "./liquidity/ILiquidityRaise.sol";
import { LiquidityRaiseTracker } from "./liquidity/LiquidityRaiseTracker.sol";
import { ILiquidityRaiseFactory } from "./liquidity/ILiquidityRaiseFactory.sol";

contract CoinGenie is PaymentTracker, TokenTracker, LiquidityRaiseTracker {
    uint256 private constant _MAX_BPS = 10_000;
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ICoinGenieERC20 private _genie;
    ITokenFactory private _tokenFactory;
    ILiquidityRaiseFactory private _raiseFactory;

    constructor(address tokenFactory_, address liquidityRaiseFactory_, ICoinGenieERC20 genie_) payable {
        _tokenFactory = ITokenFactory(tokenFactory_);
        _raiseFactory = ILiquidityRaiseFactory(liquidityRaiseFactory_);
        _genie = genie_;

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

    function genie() external view returns (ICoinGenieERC20) {
        return _genie;
    }

    function swapGenieForEth(uint256 tokenAmount) external nonReentrant onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(_genie);
        path[1] = _UNISWAP_V2_ROUTER.WETH();
        _genie.approve(address(_UNISWAP_V2_ROUTER), tokenAmount);
        _UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function launchToken(LaunchTokenParams calldata tokenParams)
        external
        nonReentrant
        returns (ICoinGenieERC20 newToken)
    {
        address payable feeRecipient = payable(_msgSender());
        newToken = _tokenFactory.launchToken(
            tokenParams.name,
            tokenParams.symbol,
            tokenParams.totalSupply,
            feeRecipient,
            address(this),
            tokenParams.affiliateFeeRecipient,
            tokenParams.taxPercent,
            tokenParams.maxBuyPercent,
            tokenParams.maxWalletPercent,
            _discountFeeRequiredAmount,
            _discountPercent
        );

        newToken.setGenie(address(_genie));
        newToken.setCoinGenieFeePercent(_coinGenieFeePercent);

        _setTokenTracking(
            newToken,
            tokenParams.name,
            tokenParams.symbol,
            tokenParams.totalSupply,
            tokenParams.feeRecipient,
            tokenParams.affiliateFeeRecipient,
            tokenParams.taxPercent,
            tokenParams.maxBuyPercent,
            tokenParams.maxWalletPercent
        );
    }

    function launchLiquidityRaise(LiquidityRaiseDetails calldata liquidityRaiseDetails)
        external
        returns (ILiquidityRaise raise)
    {
        raise = _raiseFactory.launchLiquidityRaise(
            payable(address(this)),
            ICoinGenieERC20(liquidityRaiseDetails.tokenAddress),
            liquidityRaiseDetails.desiredRaise,
            liquidityRaiseDetails.minimumInvestment,
            liquidityRaiseDetails.maximumInvestment,
            liquidityRaiseDetails.startDate,
            liquidityRaiseDetails.endDate,
            liquidityRaiseDetails.raiseAllocation,
            liquidityRaiseDetails.lpAllocation
        );

        _setLiquidityRaiseTracking(
            ICoinGenieERC20(liquidityRaiseDetails.tokenAddress),
            liquidityRaiseDetails.desiredRaise,
            liquidityRaiseDetails.minimumInvestment,
            liquidityRaiseDetails.maximumInvestment,
            liquidityRaiseDetails.startDate,
            liquidityRaiseDetails.endDate,
            liquidityRaiseDetails.raiseAllocation,
            liquidityRaiseDetails.lpAllocation
        );
    }
}
