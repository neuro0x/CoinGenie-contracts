// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ERC20Factory } from "../../contracts/factory/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../../contracts/factory/AirdropERC20ClaimableFactory.sol";
import { AirdropERC20 } from "../../contracts/AirdropERC20.sol";
import { CoinGenie } from "../../contracts/CoinGenie.sol";
import { LiquidityLocker } from "../../contracts/LiquidityLocker.sol";
import { ICoinGenieERC20 } from "../../contracts/token/ICoinGenieERC20.sol";

contract E2ETest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;

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
    }

    ERC20Factory public erc20Factory;
    AirdropERC20ClaimableFactory public airdropERC20ClaimableFactory;
    AirdropERC20 public airdropERC20;
    CoinGenie public coinGenie;
    LiquidityLocker public liquidityLocker;
    ICoinGenieERC20 public coinGenieERC20;
    IUniswapV2Pair public genieLpToken;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    CoinGenieLaunchToken public coinGenieLaunchToken = CoinGenieLaunchToken({
        name: "Genie",
        symbol: "GENIE",
        totalSupply: 1_000_000_000 ether,
        affiliateFeeRecipient: payable(coinGenie),
        taxPercent: 100,
        maxBuyPercent: 500,
        maxWalletPercent: 500
    });

    function setUp() public {
        erc20Factory = new ERC20Factory();
        airdropERC20ClaimableFactory = new AirdropERC20ClaimableFactory();
        airdropERC20 = new AirdropERC20();
        coinGenie = new CoinGenie(address(erc20Factory), address(airdropERC20ClaimableFactory));
        liquidityLocker = new LiquidityLocker(0.0075 ether, address(coinGenie));

        coinGenieERC20 = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        coinGenieERC20.setGenie(payable(address(coinGenieERC20)));
        erc20Factory.setGenie(payable(address(coinGenieERC20)));

        _logCoinGenieInfo();

        for (uint256 i = 0; i < users.length; i++) {
            vm.deal(users[i], 10 ether);
        }

        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        vm.label(user3, "User 3");
        vm.label(user5, "User 4");
        vm.label(user5, "User 5");
        vm.label(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, "V2 Router");
    }

    function test_checkInitialContractAndGenieTokenSettings() public {
        // Check that the ERC20Factory and the Genie token have "genie" set to "GENIE" address
        assertEq(erc20Factory.genie(), address(coinGenieERC20));
        assertEq(coinGenieERC20.genie(), address(coinGenieERC20));

        // Check that the LiquidityLocker and GENIE have the Coin Genie as the fee recipient
        assertEq(liquidityLocker.feeRecipient(), address(coinGenie));
        // TODO: we need to set this to the Coin Genie
        assertEq(coinGenieERC20.feeRecipient(), address(this));

        // Check that the GENIE token has the Coin Genie as the affiliate fee recipient
        assertEq(coinGenieERC20.affiliateFeeRecipient(), address(coinGenie));
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
            "U1's Token",
            "ONE",
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
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
        user1Token.manualSwap();
        vm.stopPrank();
    }

    function _logCoinGenieInfo() private view {
        console.log("Coin Genie: %s", address(coinGenie));
        console.log("ERC20 Factory: %s", address(erc20Factory));
        console.log("Airdrop ERC20 Claimable Factory: %s", address(airdropERC20ClaimableFactory));
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
