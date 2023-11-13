// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ITokenFactory } from "./interfaces/ITokenFactory.sol";

import { RaiseToken } from "./tokens/RaiseToken.sol";
import { ReflectionToken } from "./tokens/ReflectionToken.sol";
import { TaxToken } from "./tokens/TaxToken.sol";

contract TokenFactory is ITokenFactory {
    modifier onlyCoinGenie(address coinGenie) {
        if (msg.sender != coinGenie) revert Unauthorized();
        _;
    }

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
        onlyCoinGenie(coinGenie)
        returns (address taxToken)
    {
        return address(
            new TaxToken(
                name,
                symbol,
                totalSupply,
                taxPercent,
                maxBuyPercent,
                maxWalletPercent,
                platformFeePercent,
                affiliate,
                owner,
                coinGenie,
                isAntiBot
            )
        );
    }

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
        onlyCoinGenie(coinGenie)
        returns (address reflectionToken)
    {
        return address(
            new ReflectionToken(
                name,
                symbol,
                tokensTotal,
                taxPercent,
                platformFeePercent,
                liquidityFeePercent,
                maxTxAmount,
                maxAccumulatedTaxThreshold,
                owner,
                coinGenie
            )
        );
    }
}
