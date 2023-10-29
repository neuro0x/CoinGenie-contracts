// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ICoinGenieERC20 } from "../tokens/ICoinGenieERC20.sol";

import { LiquidityRaise } from "./LiquidityRaise.sol";
import { ILiquidityRaise } from "./ILiquidityRaise.sol";
import { ILiquidityRaiseFactory } from "./ILiquidityRaiseFactory.sol";

contract LiquidityRaiseFactory is ILiquidityRaiseFactory {
    function launchLiquidityRaise(
        address payable coinGenie,
        ICoinGenieERC20 coinGenieERC20_,
        uint256 desiredRaise_,
        uint256 minimumInvestment_,
        uint256 maximumInvestment_,
        uint256 startDate_,
        uint256 endDate_,
        uint256 raiseAllocation_,
        uint256 lpAllocation_
    )
        external
        returns (ILiquidityRaise liquidityRaise)
    {
        liquidityRaise = new LiquidityRaise(
            coinGenie,
            coinGenieERC20_,
            desiredRaise_,
            minimumInvestment_,
            maximumInvestment_,
            startDate_,
            endDate_,
            raiseAllocation_,
            lpAllocation_
        );
    }
}
