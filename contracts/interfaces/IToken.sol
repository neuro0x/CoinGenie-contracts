// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    event LiquidityAdded();

    error TransferFailed(uint256 amount, address from, address to);
}
