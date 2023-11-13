// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ITokenFactory {
    error Unauthorized();

    function createTaxToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 taxPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent,
        uint256 platformFeePercent,
        address affiliate,
        address owner,
        address coinGenie,
        bool isAntiBot
    )
        external
        returns (address taxToken);

    function createReflectionToken(
        string memory name,
        string memory symbol,
        uint256 tokensTotal,
        uint256 taxPercent,
        uint256 platformFeePercent,
        uint256 liquidityFeePercent,
        uint256 maxTxAmount,
        uint256 maxAccumulatedTaxThreshold,
        address owner,
        address coinGenie
    )
        external
        returns (address reflectionToken);
}
