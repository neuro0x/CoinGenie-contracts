// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IPaymentTracker } from "./payments/IPaymentTracker.sol";

import { ITokenTracker } from "./tokens/ITokenTracker.sol";
import { ICoinGenieERC20 } from "./tokens/ICoinGenieERC20.sol";

import { ILiquidityRaise } from "./liquidity/ILiquidityRaise.sol";
import { ILiquidityRaiseTracker } from "./liquidity/ILiquidityRaiseTracker.sol";

interface ICoinGenie is IPaymentTracker, ILiquidityRaiseTracker {
    function swapGenieForEth(uint256 tokenAmount) external;
    function launchToken(ITokenTracker.TokenDetails calldata tokenDetails)
        external
        returns (ICoinGenieERC20 newToken);
    function launchLiquidityRaise(LiquidityRaiseDetails calldata liquidityRaiseDetails)
        external
        returns (ILiquidityRaise raise);
}
