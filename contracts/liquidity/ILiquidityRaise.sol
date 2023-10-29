// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ICoinGenieERC20 } from "../tokens/ICoinGenieERC20.sol";

interface ILiquidityRaise {
    struct Investor {
        uint256 amountInvested;
        bool claimed;
    }

    struct Raise {
        uint256 desiredRaise;
        uint256 minimumInvestment;
        uint256 maximumInvestment;
        uint256 startDate;
        uint256 endDate;
        uint256 raiseAllocation;
        uint256 lpAllocation;
        uint256 totalRaised;
    }

    event Invested(address indexed investor, uint256 amount);
    event TokensClaimed(address indexed investor, uint256 amount);

    error Unauthorized();
    error InvalidEndDate();
    error InvalidStartDate();
    error InvalidAllocations();
    error TradingAlreadyOpen();
    error InvalidDesiredRaise();
    error InvalidMinimumInvestment();
    error InvalidMaximumInvestment();
    error PresaleEnded(uint256 endDate);
    error TransferFailed(address token, address from, address to);

    function coinGenieFee() external view returns (uint256);
    function minDesiredRaise() external view returns (uint256);
    function coinGenie() external view returns (address);
    function coinGenieERC20() external view returns (ICoinGenieERC20);
    function investors() external view returns (address[] memory);
    function investorDetails(address investor) external view returns (Investor memory);
    function openTradingEnabled() external view returns (bool);
    function desiredRaise() external view returns (uint256);
    function minimumInvestment() external view returns (uint256);
    function maximumInvestment() external view returns (uint256);
    function startDate() external view returns (uint256);
    function endDate() external view returns (uint256);
    function raiseAllocation() external view returns (uint256);
    function lpAllocation() external view returns (uint256);
    function totalRaised() external view returns (uint256);
    function createPairAndAddLiquidity() external;
    function claimTokens(address investor) external;
}
