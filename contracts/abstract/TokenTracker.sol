// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ITokenTracker } from "../interfaces/ITokenTracker.sol";

abstract contract TokenTracker is ITokenTracker {
    address[] internal _launchedTokens;
    mapping(address user => TokenDetails[] tokens) internal _tokensLaunchedBy;
    mapping(address token => TokenDetails tokenDetails) internal _launchedTokenDetails;

    function getNumberOfLaunchedTokens() external view returns (uint256) {
        return _launchedTokens.length;
    }

    function getLaunchedTokensForAddress(address user) external view returns (TokenDetails[] memory tokens) {
        return _tokensLaunchedBy[user];
    }

    function _setTokenTracking(
        address newToken,
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
