// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Common
 * @dev Common items used across the CoinGenie contracts.
 */
library Common {
    /// @dev set of features supported by the token
    struct TokenConfigProperties {
        bool isBurnable;
        bool isPausable;
        bool isDeflationary;
    }
}
