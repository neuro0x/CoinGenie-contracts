// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ICoinGenieERC20 } from "../tokens/ICoinGenieERC20.sol";

import { ILiquidityRaise } from "./ILiquidityRaise.sol";

interface ILiquidityRaiseTracker {
    struct LiquidityRaiseDetails {
        address creator;
        address tokenAddress;
        uint256 index;
        uint256 desiredRaise;
        uint256 minimumInvestment;
        uint256 maximumInvestment;
        uint256 startDate;
        uint256 endDate;
        uint256 raiseAllocation;
        uint256 lpAllocation;
    }

    event LiquidityRaiseCreated(address indexed liquidityRaiseAddress, address indexed liquidityRaiseOwner);

    function liquidityRaises() external view returns (address[] memory);
    function getNumberOfLiquidityRaises() external view returns (uint256);
    function getLiquidityRaisesForAddress(address user) external view returns (LiquidityRaiseDetails[] memory);
}
