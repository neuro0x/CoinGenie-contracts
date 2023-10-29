// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ICoinGenieERC20 } from "../tokens/ICoinGenieERC20.sol";

import { LiquidityRaise } from "./LiquidityRaise.sol";
import { ILiquidityRaise } from "./ILiquidityRaise.sol";
import { ILiquidityRaiseTracker } from "./ILiquidityRaiseTracker.sol";

abstract contract LiquidityRaiseTracker is ILiquidityRaiseTracker, Ownable {
    uint256 private constant _MAX_BPS = 10_000;
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address[] internal _liquidityRaises;
    mapping(address liquidityRaise => LiquidityRaiseDetails liquidityRaiseDetails) internal _liquidityRaiseDetails;
    mapping(address user => LiquidityRaiseDetails[] liquidityRaisesCreatedBy) internal _liquidityRaisesCreatedBy;

    constructor() payable { }

    function liquidityRaises() external view returns (address[] memory) {
        return _liquidityRaises;
    }

    function getNumberOfLiquidityRaises() external view returns (uint256) {
        return _liquidityRaises.length;
    }

    function getLiquidityRaisesForAddress(address user) external view returns (LiquidityRaiseDetails[] memory) {
        return _liquidityRaisesCreatedBy[user];
    }

    function _setLiquidityRaiseTracking(
        ICoinGenieERC20 coinGenieERC20,
        uint256 desiredRaise,
        uint256 minimumInvestment,
        uint256 maximumInvestment,
        uint256 startDate,
        uint256 endDate,
        uint256 raiseAllocation,
        uint256 lpAllocation
    )
        internal
        returns (ILiquidityRaise liquidityRaise)
    {
        // Add the liquidity raise address to the array of liquidity raise addresses
        _liquidityRaises.push(address(liquidityRaise));

        // Create a new LiquidityRaiseDetails struct
        address tokenOwner = Ownable(address(coinGenieERC20)).owner();
        LiquidityRaiseDetails memory liquidityRaiseDetail = LiquidityRaiseDetails({
            creator: tokenOwner,
            tokenAddress: address(coinGenieERC20),
            index: _liquidityRaises.length - 1,
            desiredRaise: desiredRaise,
            minimumInvestment: minimumInvestment,
            maximumInvestment: maximumInvestment,
            startDate: startDate,
            endDate: endDate,
            raiseAllocation: raiseAllocation,
            lpAllocation: lpAllocation
        });

        // Add the liquidity raise details to the mapping of liquidity raise details
        _liquidityRaiseDetails[address(liquidityRaise)] = liquidityRaiseDetail;

        // Add the liquidity raise to the array of liquidity raises created by the user
        _liquidityRaisesCreatedBy[tokenOwner].push(liquidityRaiseDetail);

        // Assign ownership to the tokenOwner
        Ownable(address(liquidityRaise)).transferOwnership(coinGenieERC20.feeRecipient());

        // Emit the event
        emit LiquidityRaiseCreated(address(liquidityRaise), tokenOwner);
    }
}
