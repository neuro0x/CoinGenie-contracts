// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ITokenFactory } from "./ITokenFactory.sol";
import { CoinGenieERC20 } from "./CoinGenieERC20.sol";
import { ICoinGenieERC20 } from "./ICoinGenieERC20.sol";

contract TokenFactory is ITokenFactory {
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
        returns (ICoinGenieERC20 token)
    {
        if (affiliateFeeRecipient == address(0)) {
            affiliateFeeRecipient = coinGenie;
        }

        token = new CoinGenieERC20(
            name,
            symbol,
            totalSupply,
            feeRecipient,
            coinGenie,
            affiliateFeeRecipient,
            taxPercent,
            maxBuyPercent,
            maxWalletPercent,
            discountFeeRequiredAmount,
            discountPercent
        );

        Ownable(address(token)).transferOwnership(feeRecipient);
    }
}
