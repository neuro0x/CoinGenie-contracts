// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { ERC20Factory } from "../../contracts/factory/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../../contracts/factory/AirdropERC20ClaimableFactory.sol";
import { AirdropERC20 } from "../../contracts/AirdropERC20.sol";
import { CoinGenie } from "../../contracts/CoinGenie.sol";
import { LiquidityLocker } from "../../contracts/LiquidityLocker.sol";

contract E2ETest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;

    ERC20Factory public erc20Factory;
    AirdropERC20ClaimableFactory public airdropERC20ClaimableFactory;
    AirdropERC20 public airdropERC20;
    CoinGenie public coinGenie;
    LiquidityLocker public liquidityLocker;

    function setUp() public {
        erc20Factory = new ERC20Factory();
        airdropERC20ClaimableFactory = new AirdropERC20ClaimableFactory();
        airdropERC20 = new AirdropERC20();
        coinGenie = new CoinGenie(address(erc20Factory), address(airdropERC20ClaimableFactory));
        liquidityLocker = new LiquidityLocker(0.0075 ether, address(coinGenie));
    }
}
