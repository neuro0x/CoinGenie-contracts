// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ITokenTracker } from "./ITokenTracker.sol";

interface ICoinGenie is ITokenTracker {
    event TaxTokenLaunched(address taxToken);
    event ReflectionTokenLaunched(address reflectionToken);

    function genieToken() external view returns (address);
    function tokenFactory() external view returns (address);
    function setPlatformFee(uint256 platformFee_) external;
    function updateTokenFactory(address tokenFactory_) external;
    function launchTaxToken(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 taxPercent_,
        uint256 maxBuyPercent_,
        uint256 platformFeePercent_,
        address affiliate,
        address owner_,
        address coinGenie_,
        bool isAntiBot_
    )
        external
        payable
        returns (address taxToken);
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
        returns (address reflectionToken);
}
