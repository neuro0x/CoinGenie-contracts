// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ITokenTracker } from "./ITokenTracker.sol";
import { ICoinGenieERC20 } from "./ICoinGenieERC20.sol";

abstract contract TokenTracker is ITokenTracker, Ownable {
    uint256 private constant _MAX_BPS = 10_000;
    uint256 internal _coinGenieFeePercent = 100;
    uint256 internal _discountPercent = 5000;
    uint256 internal _discountFeeRequiredAmount = 100_000 ether;

    address[] internal _launchedTokens;
    mapping(address user => TokenDetails[] tokens) internal _tokensLaunchedBy;
    mapping(address token => TokenDetails tokenDetails) internal _launchedTokenDetails;

    function coinGenieFeePercent() external view returns (uint256) {
        return _coinGenieFeePercent;
    }

    function discountPercent() external view returns (uint256) {
        return _discountPercent;
    }

    function discountFeeRequiredAmount() external view returns (uint256) {
        return _discountFeeRequiredAmount;
    }

    function getNumberOfLaunchedTokens() external view returns (uint256) {
        return _launchedTokens.length;
    }

    function getLaunchedTokensForAddress(address _address) external view returns (TokenDetails[] memory tokens) {
        return _tokensLaunchedBy[_address];
    }

    function setCoinGenieFeePercent(uint256 percent) external onlyOwner {
        if (percent > _MAX_BPS) {
            revert ExceedsMaxFeePercent(percent, _MAX_BPS);
        }

        _coinGenieFeePercent = percent;
    }

    function setDiscountPercent(uint256 percent) external onlyOwner {
        if (percent > _MAX_BPS) {
            revert ExceedsMaxDiscountPercent(percent, _MAX_BPS);
        }

        _discountPercent = percent;
        emit DiscountPercentSet(percent);
    }

    function setDiscountFeeRequiredAmount(uint256 amount) external onlyOwner {
        _discountFeeRequiredAmount = amount;
        emit DiscountFeeRequiredAmountSet(amount);
    }

    function _setTokenTracking(
        ICoinGenieERC20 newToken,
        string calldata name,
        string calldata symbol,
        uint256 totalSupply,
        address feeRecipient,
        address affiliateFeeRecipient,
        uint256 taxPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent
    )
        internal
    {
        _launchedTokens.push(address(newToken));
        TokenDetails memory tokenDetails = TokenDetails({
            index: _launchedTokens.length - 1,
            tokenAddress: address(newToken),
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            feeRecipient: feeRecipient,
            affiliateFeeRecipient: affiliateFeeRecipient,
            taxPercent: taxPercent,
            maxBuyPercent: maxBuyPercent,
            maxWalletPercent: maxWalletPercent
        });

        if (_tokensLaunchedBy[feeRecipient].length != 0) {
            // If the token is not a new user, update the affiliateFeeRecipient to be their first one
            tokenDetails.affiliateFeeRecipient = _tokensLaunchedBy[feeRecipient][0].affiliateFeeRecipient;
        }

        _tokensLaunchedBy[feeRecipient].push(tokenDetails);
        _launchedTokenDetails[address(newToken)] = tokenDetails;

        emit ERC20Launched(address(newToken), msg.sender);
    }
}
