// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ICoinGenieERC20 } from "./ICoinGenieERC20.sol";

interface ITokenTracker {
    struct LaunchTokenParams {
        string name;
        string symbol;
        address feeRecipient;
        address affiliateFeeRecipient;
        uint256 totalSupply;
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
    }

    struct TokenDetails {
        string name;
        string symbol;
        address tokenAddress;
        address feeRecipient;
        address affiliateFeeRecipient;
        uint256 index;
        uint256 totalSupply;
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
    }

    event DiscountPercentSet(uint256 indexed percent);
    event DiscountFeeRequiredAmountSet(uint256 indexed amount);
    event ERC20Launched(address indexed newTokenAddress, address indexed tokenOwner);

    error ExceedsMaxFeePercent(uint256 percent, uint256 maxBps);
    error ExceedsMaxDiscountPercent(uint256 percent, uint256 maxBps);

    function coinGenieFeePercent() external view returns (uint256);
    function discountPercent() external view returns (uint256);
    function discountFeeRequiredAmount() external view returns (uint256);
    function getNumberOfLaunchedTokens() external view returns (uint256);
    function getLaunchedTokensForAddress(address _address) external view returns (TokenDetails[] memory tokens);
    function setCoinGenieFeePercent(uint256 percent) external;
    function setDiscountPercent(uint256 percent) external;
    function setDiscountFeeRequiredAmount(uint256 amount) external;
}
