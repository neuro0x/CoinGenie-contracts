// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IToken } from "./IToken.sol";

interface ITaxToken is IToken {
    error BadRequest();
    error Unauthorized();
    error InvalidZeroAddress();
    error InsufficientETH(uint256 amount, uint256 minAmount);
    error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);
    error SubceedsMinAmount(uint256 amount, uint256 minAmount);
    error InsufficientTokens(uint256 amount, uint256 minAmount);

    event LiquidityRemoved();
    event AntiBotSet(bool enabled);
    event TradeRestrictionsRemoved();
    event TradingOpened(address indexed pair);
    event MaxBuyPercentSet(uint256 indexed maxBuyPercent);
    event MaxWalletPercentSet(uint256 indexed maxWalletPercent);
    event EthSentToFee(uint256 indexed feeRecipientShare, uint256 indexed coinGenieShare);

    struct FeeTakers {
        address feeRecipient;
        address platformFeeRecipient;
        address affiliateFeeRecipient;
    }

    struct FeePercentages {
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
        uint256 platformFeePercent;
    }

    struct TradeRestrictions {
        bool isTradingOpen;
        bool isInSwap;
        bool isAntiBot;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
    }

    function addLiquidity(uint256 amountToLP) external payable;
    function affiliateFeeRecipient() external view returns (address);
    function amountEthReceived(address feeRecipient_) external view returns (uint256);
    function burn(uint256 amount) external;
    function feeRecipient() external view returns (address);
    function platformFeeRecipient() external view returns (address);
    function isAntiBot() external view returns (bool);
    function isTradingOpen() external view returns (bool);
    function lpToken() external view returns (address);
    function manualSwap(uint256 amount) external;
    function maxBuyPercent() external view returns (uint256);
    function maxWalletPercent() external view returns (uint256);
    function openTrading(uint256 amountToLP) external payable;
    function platformFeePercent() external view returns (uint256);
    function removeLiquidity(uint256 amountToRemove) external;
    function removeTradeRestrictions() external;
    function setAntiBot(bool isAntiBot_) external;
    function setMaxBuyPercent(uint256 maxBuyPercent_) external;
    function setMaxWalletPercent(uint256 maxWalletPercent_) external;
    function taxPercent() external view returns (uint256);
}
