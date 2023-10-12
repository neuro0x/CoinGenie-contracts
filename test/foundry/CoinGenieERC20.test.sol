// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { CoinGenie } from "../../contracts/CoinGenie.sol";

import { ICoinGenieERC20 } from "../../contracts/token/ICoinGenieERC20.sol";

import { ERC20Factory } from "../../contracts/factory/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../../contracts/factory/AirdropERC20ClaimableFactory.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract CoinGenieERC20Test is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant MAX_TAX = 2000;
    uint256 public constant MIN_LIQUIDITY = 1 ether;
    uint256 public constant MIN_LIQUIDITY_TOKEN = 1 ether;

    CoinGenie public coinGenie;
    ERC20Factory public coinGenieERC20Factory;
    AirdropERC20ClaimableFactory public coinGenieAirdropFactory;
    ICoinGenieERC20 public coinGenieERC20;
    MockERC20 public mockERC20;

    struct LaunchToken {
        string name;
        string symbol;
        uint256 totalSupply;
        address payable feeRecipient;
        address payable affiliateFeeRecipient;
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
    }

    LaunchToken public coinGenieLaunchToken = LaunchToken({
        name: "Genie",
        symbol: "GENIE",
        totalSupply: MAX_TOKEN_SUPPLY,
        feeRecipient: payable(address(this)),
        affiliateFeeRecipient: payable(address(this)),
        taxPercent: 1000,
        maxBuyPercent: 500,
        maxWalletPercent: 500
    });

    function setUp() public {
        coinGenieERC20Factory = new ERC20Factory();
        coinGenieAirdropFactory = new AirdropERC20ClaimableFactory();
        coinGenie = new CoinGenie(address(coinGenieERC20Factory), address(coinGenieAirdropFactory));
        coinGenieERC20 = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        coinGenieERC20Factory.setCoinGenie(payable(address(coinGenie)));
        coinGenieERC20Factory.setGenie(address(coinGenieERC20));
        coinGenieERC20.setGenie(payable(address(coinGenieERC20)));
    }

    function test_name() public {
        assertEq(coinGenieERC20.name(), coinGenieLaunchToken.name);
    }

    function test_symbol() public {
        assertEq(coinGenieERC20.symbol(), coinGenieLaunchToken.symbol);
    }

    function test_decimals() public {
        assertEq(coinGenieERC20.decimals(), 18);
    }

    function test_tokenTotalSupply() public {
        assertEq(coinGenieERC20.totalSupply(), coinGenieLaunchToken.totalSupply);
    }

    function test_tokenOwner() public {
        assertEq(Ownable(address(coinGenieERC20)).owner(), address(this));
    }

    function test_affiliateFeeRecipient() public {
        assertEq(coinGenieERC20.affiliateFeeRecipient(), coinGenieLaunchToken.affiliateFeeRecipient);
    }

    function test_feeRecipient() public {
        assertEq(coinGenieERC20.feeRecipient(), coinGenieLaunchToken.feeRecipient);
    }

    function test_taxPercent() public {
        assertEq(coinGenieERC20.taxPercent(), coinGenieLaunchToken.taxPercent);
    }

    function test_openTrading_payInGenie() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        coinGenieERC20.approve(address(testToken), testToken.discountFeeRequiredAmount());

        testToken.createPairAndAddLiquidity{ value: 10 ether }(10 ether, true);
        assertEq(testToken.isSwapEnabled(), true);
    }

    function test_openTrading_NoPayInGenie() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.createPairAndAddLiquidity{ value: 10 ether }(10 ether, false);
        assertEq(testToken.isSwapEnabled(), true);
    }

    function testFuzz_transfer_tradingClosed_amount(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= balance / 2);
        vm.assume(amount > 10_000);

        // coinGenieERC20.createPairAndAddLiquidity{ value: 10 ether }(balance / 2, false);

        address to1 = address(0x1);
        address to2 = address(0x2);
        coinGenieERC20.transfer(to1, amount);
        assertEq(coinGenieERC20.balanceOf(to1), amount);

        vm.prank(to1);
        coinGenieERC20.transfer(to2, amount);
        assertLe(coinGenieERC20.balanceOf(to2), amount);
    }

    function testFuzz_transferFrom_tradingClosed_amount(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= balance / 2);
        vm.assume(amount > 10_000);

        // coinGenieERC20.createPairAndAddLiquidity{ value: 10 ether }(balance / 2, false);

        address to1 = address(0x1);
        coinGenieERC20.approve(to1, type(uint256).max);

        vm.prank(to1);
        coinGenieERC20.transferFrom(address(this), to1, amount);
        assertEq(coinGenieERC20.balanceOf(to1), amount);
    }

    function testFuzz_burn(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount > 0);
        vm.assume(amount <= balance);

        coinGenieERC20.burn(amount);

        assertEq(coinGenieERC20.balanceOf(address(this)), balance - amount);
        assertEq(coinGenieERC20.totalSupply(), balance - amount);
    }
}
