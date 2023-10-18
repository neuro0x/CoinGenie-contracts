// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { CoinGenie } from "../../contracts/CoinGenie.sol";

import { ICoinGenieERC20 } from "../../contracts/token/ICoinGenieERC20.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract CoinGenieERC20Test is Test {
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant MAX_TAX = 2000;
    uint256 public constant MIN_LIQUIDITY = 1 ether;
    uint256 public constant MIN_LIQUIDITY_TOKEN = 1 ether;

    CoinGenie public coinGenie;
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

    receive() external payable { }

    function setUp() public {
        coinGenie = new CoinGenie();
        coinGenieERC20 = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function test_owner() public {
        assertEq(Ownable(address(coinGenieERC20)).owner(), address(this));
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

    function test_totalSupply() public {
        assertEq(coinGenieERC20.totalSupply(), coinGenieLaunchToken.totalSupply);
    }

    function test_feeRecipient() public {
        assertEq(coinGenieERC20.feeRecipient(), coinGenieLaunchToken.feeRecipient);
    }

    function test_affiliateFeeRecipient() public {
        assertEq(coinGenieERC20.affiliateFeeRecipient(), coinGenieLaunchToken.affiliateFeeRecipient);
    }

    function test_coinGenie() public {
        assertEq(address(coinGenieERC20.coinGenie()), address(coinGenie));
    }

    function test_genie() public {
        assertEq(address(coinGenie.genie()), address(coinGenieERC20));
    }

    function test_isTradingOpen() public {
        assertEq(coinGenieERC20.isTradingOpen(), false);
    }

    function test_isSwapEnabled() public {
        assertEq(coinGenieERC20.isSwapEnabled(), false);
    }

    function test_taxPercent() public {
        assertEq(coinGenieERC20.taxPercent(), coinGenieLaunchToken.taxPercent);
    }

    function test_maxBuyPercent() public {
        assertEq(coinGenieERC20.maxBuyPercent(), coinGenieLaunchToken.maxBuyPercent);
    }

    function test_maxWalletPercent() public {
        assertEq(coinGenieERC20.maxWalletPercent(), coinGenieLaunchToken.maxWalletPercent);
    }

    function test_discountFeeRequiredAmount() public {
        assertEq(coinGenieERC20.discountFeeRequiredAmount(), 100_000 ether);
    }

    function test_discountPercent() public {
        assertEq(coinGenieERC20.discountPercent(), 5000);
    }

    function test_lpToken() public {
        assertEq(coinGenieERC20.lpToken(), address(0));
    }

    function test_amountEthReceived() public {
        assertEq(coinGenieERC20.amountEthReceived(address(this)), 0);
    }

    function test_balanceOf() public {
        assertEq(coinGenieERC20.balanceOf(address(this)), coinGenieLaunchToken.totalSupply);
    }

    function testFuzz_burn(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount > 0);
        vm.assume(amount <= balance);

        coinGenieERC20.burn(amount);

        assertEq(coinGenieERC20.balanceOf(address(this)), balance - amount);
        assertEq(coinGenieERC20.totalSupply(), balance - amount);
    }

    function testFuzz_transfer_tradingClosed_amount(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= coinGenieERC20.maxWalletPercent() * balance / 10_000);
        vm.assume(amount > 0);

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

    function test_manualSwap() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.createPairAndAddLiquidity{ value: 0.5 ether }(testToken.totalSupply() / 4, false);
        testToken.transfer(address(testToken), testToken.totalSupply() / 4);
        testToken.manualSwap(testToken.balanceOf(address(testToken)));

        assertEq(testToken.balanceOf(address(testToken)), 0);
    }

    function test_createPairAndAddLiquidity_payInGenie() public {
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

    function test_createPairAndAddLiquidity_NoPayInGenie() public {
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

    function testFuzz_addLiquidity_NoPayInGenie(uint256 amountToLP) public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
        vm.assume(amountToLP >= MIN_LIQUIDITY_TOKEN);
        vm.assume(amountToLP <= testToken.balanceOf(address(this)) / 2);
        testToken.createPairAndAddLiquidity{ value: 0.5 ether }(amountToLP, false);

        IUniswapV2Pair lpToken = IUniswapV2Pair(testToken.lpToken());
        uint256 coinGenieBalanceBefore = address(coinGenie).balance;
        uint256 tokenBalanceBefore = testToken.balanceOf(address(this));
        uint256 lpTokenBalanceBefore = lpToken.balanceOf(address(this));

        testToken.addLiquidity{ value: 0.5 ether }(tokenBalanceBefore, false);

        assertEq(
            coinGenieBalanceBefore + 0.005 ether, address(coinGenie).balance, "coinGenieBalanceBelfore < balanceAfter"
        );
        assertEq(0, testToken.balanceOf(address(this)), "testToken.balanceOf(address(this)) == 0");
        assertLt(lpTokenBalanceBefore, lpToken.balanceOf(address(this)), "lpTokenBalanceBefore < lpTokenBalanceAfter");
    }

    function testFuzz_addLiquidity_PayInGenie(uint256 amountToLP) public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
        vm.assume(amountToLP >= MIN_LIQUIDITY_TOKEN);
        vm.assume(amountToLP <= testToken.balanceOf(address(this)) / 2);
        testToken.createPairAndAddLiquidity{ value: 0.5 ether }(amountToLP, false);

        IUniswapV2Pair lpToken = IUniswapV2Pair(testToken.lpToken());
        uint256 coinGenieBalanceBefore = address(coinGenie).balance;
        uint256 tokenBalanceBefore = testToken.balanceOf(address(this));
        uint256 lpTokenBalanceBefore = lpToken.balanceOf(address(this));
        uint256 genieBalanceBefore = coinGenieERC20.balanceOf(address(this));

        coinGenieERC20.approve(address(testToken), testToken.discountFeeRequiredAmount());
        testToken.addLiquidity{ value: 0.5 ether }(tokenBalanceBefore, true);

        assertEq(coinGenieERC20.balanceOf(address(this)), genieBalanceBefore - coinGenie.discountFeeRequiredAmount());
        assertEq(
            coinGenieBalanceBefore + (0.005 ether * coinGenie.discountPercent()) / MAX_BPS,
            address(coinGenie).balance,
            "coinGenieBalanceBelfore < balanceAfter"
        );
        assertEq(0, testToken.balanceOf(address(this)), "testToken.balanceOf(address(this)) == 0");
        assertLt(lpTokenBalanceBefore, lpToken.balanceOf(address(this)), "lpTokenBalanceBefore < lpTokenBalanceAfter");
    }

    function testFuzz_removeLiquidity() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
        testToken.createPairAndAddLiquidity{ value: 0.5 ether }(testToken.totalSupply(), false);
        IUniswapV2Pair lpToken = IUniswapV2Pair(testToken.lpToken());
        lpToken.approve(address(testToken), lpToken.balanceOf(address(this)));
        testToken.removeLiquidity(lpToken.balanceOf(address(this)));

        assertEq(lpToken.balanceOf(address(this)), 0);
    }

    function testFail_setGenie() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setGenie(address(this));
    }

    function testFuzz_setMaxBuyPercent(uint256 maxBuyPercent) public {
        vm.assume(maxBuyPercent <= MAX_BPS);
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setMaxBuyPercent(maxBuyPercent);
        assertEq(testToken.maxBuyPercent(), maxBuyPercent);
    }

    function testFail_setMaxBuyPercent() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setMaxBuyPercent(10_001);
    }

    function testFuzz_setMaxWalletPercent(uint256 maxWalletPercent) public {
        vm.assume(maxWalletPercent <= MAX_BPS);
        vm.assume(maxWalletPercent > 100);
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setMaxWalletPercent(maxWalletPercent);
        assertEq(testToken.maxWalletPercent(), maxWalletPercent);
    }

    function testFail_setMaxWalletPercent_gt() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setMaxWalletPercent(10_001);
    }

    function testFail_setMaxWalletPercent_lt() public {
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setMaxWalletPercent(99);
    }

    function testFuzz_setFeeRecipient(address feeRecipient) public {
        vm.assume(feeRecipient != address(0));
        ICoinGenieERC20 testToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        testToken.setFeeRecipient(payable(feeRecipient));
        assertEq(testToken.feeRecipient(), payable(feeRecipient));
        assertEq(Ownable(address(testToken)).owner(), feeRecipient);
    }
}
