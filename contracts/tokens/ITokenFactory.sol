// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ICoinGenieERC20 } from "./ICoinGenieERC20.sol";

interface ITokenFactory {
    function launchToken(
        string calldata name,
        string calldata symbol,
        uint256 totalSupply,
        address feeRecipient,
        address coinGenie,
        address affiliateFeeRecipient,
        uint256 taxPercent,
        uint256 maxBuyPercent,
        uint256 maxWalletPercent,
        uint256 discountFeeRequiredAmount,
        uint256 discountPercent
    )
        external
        returns (ICoinGenieERC20 token);
}
