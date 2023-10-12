// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICoinGenieERC20 is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function feeRecipient() external view returns (address payable);
    function coinGenie() external view returns (address payable);
    function genie() external view returns (address payable);
    function affiliateFeeRecipient() external view returns (address payable);
    function isTradingOpen() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function taxPercent() external view returns (uint256);
    function maxBuyPercent() external view returns (uint256);
    function maxWalletPercent() external view returns (uint256);
    function discountFeeRequiredAmount() external view returns (uint256);
    function lpToken() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function amountEthReceived(address feeRecipient_) external view returns (uint256);
    function burn(uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function manualSwap() external;
    function createPairAndAddLiquidity(uint256 amountToLP, bool payInGenie) external payable returns (address);
    function addLiquidity(uint256 amountToLP, bool payInGenie) external payable;
    function removeLiquidity(uint256 amountToRemove) external;
    function setGenie(address payable genie_) external;
    function setFeeRecipient(address payable feeRecipient_) external;
    function setMaxBuyPercent(uint256 maxBuyPercent_) external;
    function setMaxWalletPercent(uint256 maxWalletPercent_) external;
}
