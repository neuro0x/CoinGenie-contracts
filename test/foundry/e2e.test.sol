// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { CoinGenie } from "../../contracts/CoinGenie.sol";

import { AirdropERC20 } from "../../contracts/airdrop/AirdropERC20.sol";

import { TokenTracker } from "../../contracts/tokens/TokenTracker.sol";
import { TokenFactory } from "../../contracts/tokens/TokenFactory.sol";
import { ITokenTracker } from "../../contracts/tokens/ITokenTracker.sol";
import { ITokenFactory } from "../../contracts/tokens/ITokenFactory.sol";
import { CoinGenieERC20 } from "../../contracts/tokens/CoinGenieERC20.sol";
import { ICoinGenieERC20 } from "../../contracts/tokens/ICoinGenieERC20.sol";

import { LiquidityLocker } from "../../contracts/liquidity/LiquidityLocker.sol";
import { LiquidityRaiseFactory } from "../../contracts/liquidity/LiquidityRaiseFactory.sol";
import { ILiquidityRaiseFactory } from "../../contracts/liquidity/ILiquidityRaiseFactory.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract E2ETest is Test {
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant DISCOUNT_PERCENT = 5000;
    uint256 public constant DISCOUNT_AMOUNT_REQUIRED = 100_000 ether;

    address[] private users = [
        0xBe79b43B1505290DFE04294a433963dbeea736BB,
        0x633Bf832Dc39C0025a7aEaa165ec91ACF02063D5,
        0xbb6712A513C2d7F3E17A40d095a773c5d98574B2,
        0xF14A30C09897d2C7481c5907D01Ec58Ec09555af,
        0xD07519F723960a230Acee575F9928F4D391E7bD3
    ];

    address user1 = 0xBe79b43B1505290DFE04294a433963dbeea736BB;
    address user2 = 0x633Bf832Dc39C0025a7aEaa165ec91ACF02063D5;
    address user3 = 0xbb6712A513C2d7F3E17A40d095a773c5d98574B2;
    address user4 = 0xF14A30C09897d2C7481c5907D01Ec58Ec09555af;
    address user5 = 0xD07519F723960a230Acee575F9928F4D391E7bD3;

    struct CoinGenieLaunchToken {
        string name;
        string symbol;
        address payable affiliateFeeRecipient;
        uint256 totalSupply;
        uint256 taxPercent;
        uint256 maxBuyPercent;
        uint256 maxWalletPercent;
        uint256 discountFeeRequiredAmount;
        uint256 discountPercent;
    }

    AirdropERC20 public airdropERC20;
    CoinGenie public coinGenie;
    LiquidityLocker public liquidityLocker;
    ICoinGenieERC20 public genieToken;
    ICoinGenieERC20 public coinGenieERC20;
    ITokenFactory public erc20Factory;
    ILiquidityRaiseFactory public liquidityRaiseFactory;
    IUniswapV2Pair public genieLpToken;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ITokenTracker.TokenDetails public coinGenieLaunchToken;

    function setUp() public {
        genieToken = new CoinGenieERC20(
            "Genie",
            "GENIE",
            MAX_TOKEN_SUPPLY,
            payable(address(this)),
            payable(address(0x0123)),
            payable(address(this)),
            0,
            MAX_BPS,
            MAX_BPS,
            0,
            0
        );

        airdropERC20 = new AirdropERC20();
        erc20Factory = new TokenFactory();
        liquidityRaiseFactory = new LiquidityRaiseFactory();
        coinGenie = new CoinGenie(address(erc20Factory), address(liquidityRaiseFactory), genieToken);
        liquidityLocker = new LiquidityLocker(0.0075 ether, address(coinGenie));

        coinGenieERC20 = coinGenie.launchToken(
            ITokenTracker.LaunchTokenParams({
                name: "Coin Genie",
                symbol: "COIN",
                feeRecipient: address(this),
                affiliateFeeRecipient: address(coinGenie),
                totalSupply: MAX_TOKEN_SUPPLY,
                taxPercent: 0,
                maxBuyPercent: MAX_BPS,
                maxWalletPercent: MAX_BPS
            }),
            DISCOUNT_AMOUNT_REQUIRED,
            DISCOUNT_PERCENT
        );

        coinGenieLaunchToken = TokenTracker.TokenDetails({
            name: coinGenieERC20.name(),
            symbol: coinGenieERC20.symbol(),
            tokenAddress: address(coinGenieERC20),
            feeRecipient: coinGenieERC20.feeRecipient(),
            affiliateFeeRecipient: coinGenieERC20.affiliateFeeRecipient(),
            index: 0,
            totalSupply: coinGenieERC20.totalSupply(),
            taxPercent: coinGenieERC20.taxPercent(),
            maxBuyPercent: coinGenieERC20.maxBuyPercent(),
            maxWalletPercent: coinGenieERC20.maxWalletPercent()
        });

        // _logCoinGenieInfo();

        for (uint256 i = 0; i < users.length;) {
            vm.deal(users[i], 10 ether);

            unchecked {
                i = i + 1;
            }
        }

        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        vm.label(user3, "User 3");
        vm.label(user5, "User 4");
        vm.label(user5, "User 5");
        vm.label(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, "V2 Router");
        vm.label(address(coinGenie), "Coin Genie");
        vm.label(address(coinGenieERC20), "Coin Genie ERC20");
        vm.label(address(liquidityLocker), "Liquidity Locker");
        vm.label(address(airdropERC20), "Airdrop ERC20");
        vm.label(address(erc20Factory), "ERC20 Factory");
        vm.label(address(liquidityRaiseFactory), "Liquidity Raise Factory");
        vm.label(address(this), "E2E Test");
    }

    function test_checkInitialContractAndGenieTokenSettings() public {
        // Check that the Genie token have "genie" set to "GENIE" address
        assertEq(coinGenieERC20.genie(), address(coinGenieERC20), "Genie is not set.");

        // Check that the LiquidityLocker and GENIE have the Coin Genie as the fee recipient
        assertEq(liquidityLocker.feeRecipient(), address(coinGenie), "LiquidityLocker feeRecipient is not set.");
        assertEq(coinGenieERC20.feeRecipient(), address(this), "Token feeRecipient is not set.");

        // Check that the GENIE token has the Coin Genie as the affiliate fee recipient
        assertEq(coinGenieERC20.affiliateFeeRecipient(), address(coinGenie), "Token affiliateFeeRecipient is not set.");
    }

    function test_checkGenieTokenOpenTrading() public {
        // Open Trading on the GENIE token
        coinGenieERC20.createPairAndAddLiquidity{ value: 0.5 ether }(50_000_000 ether, false);
        // Check that booleans were properly flipped
        assertEq(coinGenieERC20.isTradingOpen(), true);
        assertEq(coinGenieERC20.isSwapEnabled(), true);
    }

    function test_e2e() public {
        // Launch a new token from a different user
        vm.startPrank(user1);
        ICoinGenieERC20 user1Token = coinGenie.launchToken(
            TokenTracker.TokenDetails({
                name: "U1's Token",
                symbol: "U1",
                tokenAddress: address(0),
                feeRecipient: payable(user1),
                affiliateFeeRecipient: payable(user1),
                index: 0,
                totalSupply: MAX_TOKEN_SUPPLY,
                taxPercent: 500,
                maxBuyPercent: MAX_BPS,
                maxWalletPercent: MAX_BPS
            }),
            DISCOUNT_AMOUNT_REQUIRED,
            DISCOUNT_PERCENT
        );
        vm.label(address(user1Token), "U1's Token");

        // Open trading for the new token
        IUniswapV2Pair user1LpToken = IUniswapV2Pair(
            user1Token.createPairAndAddLiquidity{ value: 0.5 ether }(coinGenieLaunchToken.totalSupply / 2, false)
        );
        vm.label(address(user1LpToken), "U1's LP Token");
        assertEq(user1Token.isTradingOpen(), true);
        assertEq(user1Token.isSwapEnabled(), true);
        assertEq(user1Token.balanceOf(user1), coinGenieLaunchToken.totalSupply / 2);
        vm.stopPrank();

        // Initiate swaps from this user and different users
        _swapEthForTokens(user1Token, 0.01 ether, user1);

        _swapEthForTokens(user1Token, 0.01 ether, user2);
        _swapEthForTokens(user1Token, 0.01 ether, user3);
        _swapEthForTokens(user1Token, 0.01 ether, user4);
        _swapEthForTokens(user1Token, 0.01 ether, user5);

        // Sell the tokens
        _swapTokensForEth(user1Token, user1Token.balanceOf(user2), user2);
        _swapTokensForEth(user1Token, user1Token.balanceOf(user3), user3);
        _swapTokensForEth(user1Token, user1Token.balanceOf(user4), user4);
        _swapTokensForEth(user1Token, user1Token.balanceOf(user5), user5);

        vm.startPrank(user1);
        uint256 user1BalanceBefore = user1.balance;
        uint256 user1LpTokenBalanceBefore = user1LpToken.balanceOf(user1);
        user1Token.addLiquidity{ value: 0.5 ether }((user1Token.balanceOf(user1) * 500) / 10_000, false);
        vm.stopPrank();

        assertLt(user1.balance, user1BalanceBefore);
        assertGt(user1LpToken.balanceOf(user1), user1LpTokenBalanceBefore);

        vm.startPrank(user1);
        user1Token.manualSwap(user1Token.balanceOf(address(user1Token)) / 2);
        vm.stopPrank();
    }

    function _logCoinGenieInfo() private view {
        console.log("Coin Genie: %s", address(coinGenie));
        console.log("Airdrop ERC20: %s", address(airdropERC20));
        console.log("Liquidity Locker: %s", address(liquidityLocker));
        console.log("Coin Genie ERC20: %s", address(coinGenieERC20));
        console.log("\tAffiliate Fee Recipient: %s", coinGenieERC20.affiliateFeeRecipient());
        console.log("\tFee Recipient: %s", coinGenieERC20.feeRecipient());
        console.log("\tTax Percent: %s", coinGenieERC20.taxPercent());
        console.log("\tMax Buy Percent: %s", coinGenieERC20.maxBuyPercent());
        console.log("\tMax Wallet Percent: %s", coinGenieERC20.maxWalletPercent());
        console.log("\tTotal Supply: %s", coinGenieERC20.totalSupply());
        console.log("\n");
    }

    function _logBalances(ICoinGenieERC20 token, IUniswapV2Pair lpToken) private view {
        console.log("U1's balance: %s", token.balanceOf(user1));
        console.log("U2's balance: %s", token.balanceOf(user2));
        console.log("U3's balance: %s", token.balanceOf(user3));
        console.log("U4's balance: %s", token.balanceOf(user4));
        console.log("U5's balance: %s", token.balanceOf(user5));

        console.log("U1's LP balance: %s", lpToken.balanceOf(user1));
        console.log("U2's LP balance: %s", lpToken.balanceOf(user2));
        console.log("U3's LP balance: %s", lpToken.balanceOf(user3));
        console.log("U4's LP balance: %s", lpToken.balanceOf(user4));
        console.log("U5's LP balance: %s", lpToken.balanceOf(user5));

        console.log("U1's GENIE balance: %s", coinGenieERC20.balanceOf(user1));
        console.log("U2's GENIE balance: %s", coinGenieERC20.balanceOf(user2));
        console.log("U3's GENIE balance: %s", coinGenieERC20.balanceOf(user3));
        console.log("U4's GENIE balance: %s", coinGenieERC20.balanceOf(user4));
        console.log("U5's GENIE balance: %s", coinGenieERC20.balanceOf(user5));

        console.log("U1's ETH balance: %s", user1.balance);
        console.log("U2's ETH balance: %s", user2.balance);
        console.log("U3's ETH balance: %s", user3.balance);
        console.log("U4's ETH balance: %s", user4.balance);
        console.log("U5's ETH balance: %s", user5.balance);

        console.log("CoinGenie Eth Balance: %s", address(coinGenie).balance);
        console.log("CoinGenieERC20 Eth Balance: %s", address(coinGenieERC20).balance);
        console.log("\n");
    }

    function _swapEthForTokens(ICoinGenieERC20 token, uint256 amountIn, address to) private {
        address[] memory path = new address[](2);
        path[1] = address(token);
        path[0] = uniswapRouter.WETH();
        vm.prank(to);
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
            0, path, to, block.timestamp
        );
    }

    function _swapTokensForEth(ICoinGenieERC20 token, uint256 amountIn, address to) public {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapRouter.WETH();
        vm.prank(to);
        token.approve(address(uniswapRouter), amountIn);
        vm.prank(to);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, to, block.timestamp);
    }
}
