// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ICoinGenieERC20 } from "../tokens/ICoinGenieERC20.sol";

import { ILiquidityRaise } from "./ILiquidityRaise.sol";

contract LiquidityRaise is ILiquidityRaise, Ownable, ReentrancyGuard {
    using SafeERC20 for ICoinGenieERC20;

    uint256 private constant _MAX_BPS = 10_000; // 100%
    uint256 private constant _COIN_GENIE_FEE = 100; // 1%
    uint256 private immutable _MIN_DESIRED_RAISE = 0.5 ether;

    ICoinGenieERC20 private immutable _coinGenieERC20;
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable private immutable _coinGenie;

    address[] private _investors;
    mapping(address investor => Investor) private _investorDetails;

    Raise private _raise;

    modifier presaleOpen() {
        if (block.timestamp < _raise.startDate) {
            revert InvalidStartDate();
        }

        if (block.timestamp > _raise.endDate) {
            revert InvalidEndDate();
        }

        if (address(this).balance > _raise.desiredRaise) {
            revert InvalidDesiredRaise();
        }

        _;
    }

    modifier onlyTokenOwner() {
        if (msg.sender != Ownable(address(_coinGenieERC20)).owner()) {
            revert Unauthorized();
        }

        _;
    }

    modifier presaleEnded() {
        if (block.timestamp >= _raise.endDate) {
            _;
        } else {
            revert PresaleEnded(_raise.endDate);
        }
    }

    constructor(
        address payable coinGenie_,
        ICoinGenieERC20 coinGenieERC20_,
        uint256 desiredRaise_,
        uint256 minimumInvestment_,
        uint256 maximumInvestment_,
        uint256 startDate_,
        uint256 endDate_,
        uint256 raiseAllocation_,
        uint256 lpAllocation_
    ) {
        _createChecks(coinGenieERC20_, desiredRaise_, minimumInvestment_, maximumInvestment_, startDate_, endDate_);
        _validateAllocations(coinGenieERC20_, raiseAllocation_, lpAllocation_);

        _coinGenieERC20 = coinGenieERC20_;
        _coinGenieERC20.transferFrom(msg.sender, address(this), raiseAllocation_ + lpAllocation_);

        _coinGenie = coinGenie_;

        uint256 totalSupply = _coinGenieERC20.totalSupply();
        _raise = Raise({
            desiredRaise: desiredRaise_,
            minimumInvestment: minimumInvestment_,
            maximumInvestment: maximumInvestment_,
            startDate: startDate_,
            endDate: endDate_,
            raiseAllocation: (totalSupply * raiseAllocation_) / _MAX_BPS,
            lpAllocation: (totalSupply * lpAllocation_) / _MAX_BPS,
            totalRaised: 0
        });
    }

    receive() external payable presaleOpen {
        // Check if the investor has already claimed
        if (_investorDetails[msg.sender].claimed) {
            revert Unauthorized();
        }

        // Check if the investment meets the minimum investment
        uint256 amount = msg.value;
        if (amount < _raise.minimumInvestment) {
            revert InvalidMinimumInvestment();
        }

        // Check if the investment meets the maximum investment
        uint256 invested = _investorDetails[msg.sender].amountInvested + amount;
        if (invested > _raise.maximumInvestment) {
            // Refund the difference if the investor sent too much
            uint256 refund = invested - _raise.maximumInvestment;
            amount -= refund;
            payable(msg.sender).transfer(refund);
        }

        // Check if the investor has already invested
        if (_investorDetails[msg.sender].amountInvested == 0) {
            // Add the investor to the list of investors
            _investors.push(msg.sender);
        }

        // Update the investor details
        _investorDetails[msg.sender].amountInvested = amount;

        // Update the total invested
        _raise.totalRaised += amount;

        // Transfer the fee to the Coin Genie
        uint256 fee = (amount * _COIN_GENIE_FEE) / _MAX_BPS;
        (bool successCoinGenie,) = address(_coinGenie).call{ value: fee }("");
        if (!successCoinGenie) {
            revert TransferFailed(address(_coinGenieERC20), address(this), address(_coinGenie));
        }

        // Emit the event
        emit Invested(msg.sender, amount);
    }

    function coinGenieFee() external pure returns (uint256) {
        return _COIN_GENIE_FEE;
    }

    function minDesiredRaise() external pure returns (uint256) {
        return _MIN_DESIRED_RAISE;
    }

    function coinGenie() external view returns (address) {
        return address(_coinGenie);
    }

    function coinGenieERC20() external view returns (ICoinGenieERC20) {
        return _coinGenieERC20;
    }

    function investors() external view returns (address[] memory) {
        return _investors;
    }

    function investorDetails(address investor) external view returns (Investor memory) {
        return _investorDetails[investor];
    }

    function openTradingEnabled() external view returns (bool) {
        return block.timestamp >= _raise.endDate;
    }

    function desiredRaise() external view returns (uint256) {
        return _raise.desiredRaise;
    }

    function minimumInvestment() external view returns (uint256) {
        return _raise.minimumInvestment;
    }

    function maximumInvestment() external view returns (uint256) {
        return _raise.maximumInvestment;
    }

    function startDate() external view returns (uint256) {
        return _raise.startDate;
    }

    function endDate() external view returns (uint256) {
        return _raise.endDate;
    }

    function raiseAllocation() external view returns (uint256) {
        return _raise.raiseAllocation;
    }

    function lpAllocation() external view returns (uint256) {
        return _raise.lpAllocation;
    }

    function totalRaised() external view returns (uint256) {
        return _raise.totalRaised;
    }

    function createPairAndAddLiquidity() external presaleEnded onlyTokenOwner nonReentrant {
        if (_coinGenieERC20.isTradingOpen()) {
            revert TradingAlreadyOpen();
        }

        uint256 balance = address(this).balance;

        // Transfer the eth balance to the token for LP
        payable(address(_coinGenieERC20)).transfer(balance);

        // Create the pair and add liquidity
        (bool success,) = address(_coinGenieERC20).delegatecall(
            abi.encodeWithSignature("createPairAndAddLiquidity(uint256,bool)", _raise.lpAllocation, false)
        );
        if (!success) {
            revert TransferFailed(address(_coinGenieERC20), address(this), address(_coinGenieERC20));
        }
    }

    function claimTokens(address investor) external presaleEnded nonReentrant {
        // Check if the investor has already claimed
        uint256 amountInvested = _investorDetails[investor].amountInvested;
        if (_investorDetails[investor].claimed || amountInvested == 0) {
            revert Unauthorized();
        }

        // Get the amount of tokens to send to the investor
        uint256 amountToClaim = (_raise.raiseAllocation * amountInvested) / _raise.totalRaised;

        // Transfer the tokens to the investor
        _coinGenieERC20.transfer(investor, amountToClaim);

        // Update the investor claim
        _investorDetails[investor].claimed = true;

        // Emit the event
        emit TokensClaimed(investor, amountToClaim);
    }

    function _validateAllocations(
        ICoinGenieERC20 coinGenieERC20_,
        uint256 raiseAllocation_,
        uint256 lpAllocation_
    )
        private
        view
    {
        uint256 totalSupply = coinGenieERC20_.totalSupply();
        uint256 totalAllocation = (totalSupply * raiseAllocation_) / _MAX_BPS + (totalSupply * lpAllocation_) / _MAX_BPS;
        if (
            totalAllocation > totalSupply || raiseAllocation_ == 0 || lpAllocation_ == 0
                || totalAllocation > _coinGenieERC20.balanceOf(msg.sender)
        ) {
            revert InvalidAllocations();
        }
    }

    /// @notice Validates the properties of the liquidity raise
    /// @param coinGenieERC20_ - the address of the token
    /// @param desiredRaise_ - the desired raise amount
    /// @param minimumInvestment_ - the minimum investment amount
    /// @param maximumInvestment_ - the maximum investment amount
    /// @param startDate_ - the start date of the liquidity raise in seconds since unix epoch
    /// @param endDate_ - the end date of the liquidity raise in seconds since unix epoch
    function _createChecks(
        ICoinGenieERC20 coinGenieERC20_,
        uint256 desiredRaise_,
        uint256 minimumInvestment_,
        uint256 maximumInvestment_,
        uint256 startDate_,
        uint256 endDate_
    )
        private
        view
    {
        if (endDate_ <= startDate_) {
            revert InvalidEndDate();
        }

        if (desiredRaise_ < _MIN_DESIRED_RAISE) {
            revert InvalidDesiredRaise();
        }

        if (coinGenieERC20_.isTradingOpen()) {
            revert TradingAlreadyOpen();
        }

        if (minimumInvestment_ > maximumInvestment_ || minimumInvestment_ == 0) {
            revert InvalidMinimumInvestment();
        }

        if (maximumInvestment_ > desiredRaise_ || maximumInvestment_ == 0) {
            revert InvalidMaximumInvestment();
        }
    }
}
