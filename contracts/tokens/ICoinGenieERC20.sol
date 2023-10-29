// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICoinGenieERC20 is IERC20 {
    struct FeeTakers {
        address feeRecipient;
        address coinGenie;
        address affiliateFeeRecipient;
    }

    struct FeePercentages {
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
        uint256 discountFeeRequiredAmount;
        uint256 discountPercent;
        uint256 coinGenieFeePercent;
    }

    event AntiBotSet(bool enabled);
    event GenieSet(address indexed genie);
    event TradingOpened(address indexed pair);
    event FeeRecipientSet(address indexed feeRecipient);
    event MaxBuyPercentSet(uint256 indexed maxBuyPercent);
    event MaxWalletPercentSet(uint256 indexed maxWalletPercent);
    event EthSentToFee(uint256 indexed feeRecipientShare, uint256 indexed coinGenieShare);

    error Unauthorized();
    error TradingNotOpen();
    error GenieAlreadySet();
    error TradingAlreadyOpen();
    error BurnFromZeroAddress();
    error ApproveFromZeroAddress();
    error TransferFromZeroAddress();
    error InvalidCoinGenieFeePercent();
    error CoinGenieFeePercentAlreadySet();
    error InvalidTotalSupply(uint256 totalSupply);
    error InvalidMaxBuyPercent(uint256 maxBuyPercent);
    error InvalidMaxWalletPercent(uint256 maxWalletPercent);
    error InsufficientETH(uint256 amount, uint256 minAmount);
    error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);
    error InsufficientTokens(uint256 amount, uint256 minAmount);
    error InsufficientAllowance(uint256 amount, uint256 allowance);
    error TransferFailed(uint256 amount, address from, address to);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function feeRecipient() external view returns (address);
    function coinGenie() external view returns (address);
    function genie() external view returns (address);
    function affiliateFeeRecipient() external view returns (address);
    function isTradingOpen() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function taxPercent() external view returns (uint256);
    function maxBuyPercent() external view returns (uint256);
    function maxWalletPercent() external view returns (uint256);
    function discountFeeRequiredAmount() external view returns (uint256);
    function discountPercent() external view returns (uint256);
    function lpToken() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function amountEthReceived(address feeRecipient_) external view returns (uint256);
    function isAntiBot() external view returns (bool);
    function burn(uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function manualSwap(uint256 amount) external;
    function createPairAndAddLiquidity(uint256 amountToLP, bool payInGenie) external payable returns (address);
    function addLiquidity(uint256 amountToLP, bool payInGenie) external payable;
    function removeLiquidity(uint256 amountToRemove) external;
    function setGenie(address genie_) external;
    function setMaxBuyPercent(uint256 maxBuyPercent_) external;
    function setMaxWalletPercent(uint256 maxWalletPercent_) external;
    function setCoinGenieFeePercent(uint256 coinGenieFeePercent_) external;
    function setAntiBot(bool enabled) external;
}
