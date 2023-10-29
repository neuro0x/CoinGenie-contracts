// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ICoinGenieERC20 } from "../tokens/ICoinGenieERC20.sol";

import { ILiquidityRaise } from "./ILiquidityRaise.sol";

interface ILiquidityRaiseFactory {
    function launchLiquidityRaise(
        address payable coinGenie_,
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
        returns (ILiquidityRaise liquidityRaise);
}
