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

        vm.deal(users[0], 10 ether);
        vm.deal(users[1], 10 ether);
        vm.deal(users[2], 10 ether);
        vm.deal(users[3], 10 ether);
        vm.deal(users[4], 10 ether);

        vm.label(users[0], "User 0");
        vm.label(users[1], "User 1");
        vm.label(users[2], "User 2");
        vm.label(users[3], "User 3");
        vm.label(users[4], "User 4");
        vm.label(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, "V2 Router");
    }

    function test_e2e() public {
        _checkInitialContractAndGenieTokenSettings();
        _checkGenieTokenOpenTrading();

        // Launch a new token from a different user
        vm.startPrank(users[0]);
        ICoinGenieERC20 user1Token = coinGenie.launchToken(
            "User One's Token",
            "ONE",
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
        vm.label(address(user1Token), "User 1's Token");

        // Open trading for the new token
        IUniswapV2Pair user1LpToken = IUniswapV2Pair(
            user1Token.createPairAndAddLiquidity{ value: 0.5 ether }(coinGenieLaunchToken.totalSupply / 2, false)
        );
        vm.label(address(user1LpToken), "User 1's LP Token");
        assertEq(user1Token.isTradingOpen(), true);
        assertEq(user1Token.isSwapEnabled(), true);
        assertEq(user1Token.balanceOf(users[0]), coinGenieLaunchToken.totalSupply / 2);
        vm.stopPrank();

        // Initiate swaps from this user and different users
        _swapEthForTokens(user1Token, 0.05 ether, users[0]);
        _swapEthForTokens(user1Token, 0.05 ether, users[1]);
        _swapEthForTokens(user1Token, 0.05 ether, users[2]);
        _swapEthForTokens(user1Token, 0.05 ether, users[3]);
        _swapEthForTokens(user1Token, 0.05 ether, users[4]);

        // TODO: LOTs more 🥲
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

    function _checkInitialContractAndGenieTokenSettings() private {
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

    function _checkGenieTokenOpenTrading() private {
        // Open Trading on the GENIE token
        coinGenieERC20.createPairAndAddLiquidity{ value: 1 ether }(coinGenieLaunchToken.totalSupply / 2, false);
        // Check that booleans were properly flipped
        assertEq(coinGenieERC20.isTradingOpen(), true);
        assertEq(coinGenieERC20.isSwapEnabled(), true);
    }
}
