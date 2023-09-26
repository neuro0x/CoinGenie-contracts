// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "../lib/forge-std/src/Test.sol";

import { CoinGenie } from "../src/CoinGenie.sol";
import { CoinGenieERC20 } from "../src/CoinGenieERC20.sol";
import { ERC20Factory } from "../src/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../src/AirdropERC20ClaimableFactory.sol";
import { Common } from "../src/lib/Common.sol";
import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract CoinGenieERC20Test is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant MAX_TAX = 2000;
    uint256 public constant MIN_LIQUIDITY = 1 ether;
    uint256 public constant MIN_LIQUIDITY_TOKEN = 1 ether;

    CoinGenie public coinGenie;
    ERC20Factory public coinGenieERC20Factory;
    AirdropERC20ClaimableFactory public coinGenieAirdropFactory;
    CoinGenieERC20 public coinGenieERC20;
    MockERC20 public mockERC20;

    struct CoinGenieLaunchToken {
        string name;
        string symbol;
        uint256 initialSupply;
        address tokenOwner;
        Common.TokenConfigProperties customConfigProps;
        uint256 maxPerWallet;
        address affiliateFeeRecipient;
        address feeRecipient;
        uint256 feePercentage;
        uint256 burnPercentage;
    }

    CoinGenieLaunchToken public coinGenieLaunchToken;
    Common.TokenConfigProperties public tokenConfigProps;

    function setUp() public {
        coinGenieERC20Factory = new ERC20Factory();
        coinGenieAirdropFactory = new AirdropERC20ClaimableFactory();
        tokenConfigProps = Common.TokenConfigProperties({ isBurnable: true, isPausable: true, isDeflationary: true });
        coinGenieLaunchToken = CoinGenieLaunchToken({
            name: "Genie",
            symbol: "GENIE",
            initialSupply: 100_000_000_000 ether,
            tokenOwner: address(this),
            customConfigProps: tokenConfigProps,
            maxPerWallet: 100_000_000_000 ether,
            affiliateFeeRecipient: address(this),
            feeRecipient: address(this),
            feePercentage: 200,
            burnPercentage: 50
        });
        coinGenie = new CoinGenie(address(coinGenieERC20Factory), address(coinGenieAirdropFactory));
        coinGenieERC20 = CoinGenieERC20(
            payable(
                coinGenie.launchToken(
                    coinGenieLaunchToken.name,
                    coinGenieLaunchToken.symbol,
                    coinGenieLaunchToken.initialSupply,
                    coinGenieLaunchToken.tokenOwner,
                    coinGenieLaunchToken.customConfigProps,
                    coinGenieLaunchToken.maxPerWallet,
                    coinGenieLaunchToken.affiliateFeeRecipient,
                    coinGenieLaunchToken.feeRecipient,
                    coinGenieLaunchToken.feePercentage,
                    coinGenieLaunchToken.burnPercentage
                )
            )
        );

        coinGenieERC20Factory.setGenie(address(coinGenieERC20));
        coinGenieERC20.setGenie(address(coinGenieERC20));
    }

    function test_tokenName() public {
        assertEq(coinGenieERC20.name(), coinGenieLaunchToken.name);
    }

    function test_tokenSymbol() public {
        assertEq(coinGenieERC20.symbol(), coinGenieLaunchToken.symbol);
    }

    function test_tokenDecimals() public {
        assertEq(coinGenieERC20.decimals(), 18);
    }

    function test_tokenTotalSupply() public {
        assertEq(coinGenieERC20.totalSupply(), coinGenieLaunchToken.initialSupply);
    }

    function test_tokenOwner() public {
        assertEq(coinGenieERC20.owner(), coinGenieLaunchToken.tokenOwner);
    }

    function test_tokenAffiliateFeeRecipient() public {
        assertEq(coinGenieERC20.affiliateFeeRecipient(), coinGenieLaunchToken.affiliateFeeRecipient);
    }

    function test_tokenFeeRecipient() public {
        assertEq(coinGenieERC20.feeRecipient(), coinGenieLaunchToken.feeRecipient);
    }

    function test_tokenFeePercentage() public {
        assertEq(coinGenieERC20.feePercentage(), coinGenieLaunchToken.feePercentage);
    }

    function test_tokenBurnPercentage() public {
        assertEq(coinGenieERC20.burnPercentage(), coinGenieLaunchToken.burnPercentage);
    }

    function test_tokenIsBurnable() public {
        assertEq(coinGenieERC20.isBurnable(), tokenConfigProps.isBurnable);
    }

    function test_tokenIsPausable() public {
        assertEq(coinGenieERC20.isPausable(), tokenConfigProps.isPausable);
    }

    function test_tokenIsDeflationary() public {
        assertEq(coinGenieERC20.isDeflationary(), tokenConfigProps.isDeflationary);
    }

    function testFuzz_setMaxTokenAmountPerAddress(uint256 maxPerWallet) public {
        vm.assume(maxPerWallet > coinGenieERC20.maxTokenAmountPerAddress());

        coinGenieERC20.setMaxTokenAmountPerAddress(maxPerWallet);

        assertEq(coinGenieERC20.maxTokenAmountPerAddress(), maxPerWallet);
    }

    function testFuzz_setTaxConfig(address feeRecipient, uint256 feePercentage) public {
        vm.assume(feePercentage <= MAX_TAX);
        vm.assume(feeRecipient != address(0));

        coinGenieERC20.setTaxConfig(feeRecipient, feePercentage);

        assertEq(coinGenieERC20.feeRecipient(), feeRecipient);
        assertEq(coinGenieERC20.feePercentage(), feePercentage);
    }

    function testFuzz_setDeflationConfig(uint256 burnPercentage) public {
        vm.assume(burnPercentage <= MAX_TAX);

        coinGenieERC20.setDeflationConfig(burnPercentage);

        assertEq(coinGenieERC20.burnPercentage(), burnPercentage);
    }

    function test_openTrading_payInGenie() public {
        CoinGenieERC20 testToken = CoinGenieERC20(
            payable(
                coinGenie.launchToken(
                    coinGenieLaunchToken.name,
                    coinGenieLaunchToken.symbol,
                    coinGenieLaunchToken.initialSupply,
                    coinGenieLaunchToken.tokenOwner,
                    coinGenieLaunchToken.customConfigProps,
                    coinGenieLaunchToken.maxPerWallet,
                    coinGenieLaunchToken.affiliateFeeRecipient,
                    coinGenieLaunchToken.feeRecipient,
                    coinGenieLaunchToken.feePercentage,
                    coinGenieLaunchToken.burnPercentage
                )
            )
        );

        testToken.openTrading{ value: 10 ether }(10 ether, true);
        assertEq(testToken.isSwapEnabled(), true);
    }

    function testFuzz_openTrading(uint256 value, uint256 amountToLp) public {
        vm.assume(value >= MIN_LIQUIDITY);
        vm.assume(value < address(this).balance / 2);
        vm.assume(amountToLp <= coinGenieERC20.balanceOf(address(this)));
        vm.assume(amountToLp > MIN_LIQUIDITY_TOKEN);

        coinGenieERC20.openTrading{ value: value }(amountToLp, false);

        assertEq(coinGenieERC20.isSwapEnabled(), true);
    }

    function testFuzz_transfer_amount(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= balance / 2);
        vm.assume(amount > 10_000);

        coinGenieERC20.openTrading{ value: 10 ether }(balance / 2, false);

        address to1 = address(0x1);
        address to2 = address(0x2);
        coinGenieERC20.transfer(to1, amount);
        assertEq(coinGenieERC20.balanceOf(to1), amount);

        vm.prank(to1);
        coinGenieERC20.transfer(to2, amount);
        assertLt(coinGenieERC20.balanceOf(to2), amount);
    }

    function testFuzz_transferFrom_amount(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= balance / 2);
        vm.assume(amount > 10_000);

        coinGenieERC20.openTrading{ value: 10 ether }(balance / 2, false);

        address to1 = address(0x1);
        coinGenieERC20.approve(to1, type(uint256).max);

        vm.prank(to1);
        coinGenieERC20.transferFrom(address(this), to1, amount);
        assertEq(coinGenieERC20.balanceOf(to1), amount);
    }

    function testFuzz_burn(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= balance);

        coinGenieERC20.burn(amount);

        assertEq(coinGenieERC20.balanceOf(address(this)), balance - amount);
        assertEq(coinGenieERC20.totalSupply(), balance - amount);
    }

    function testFuzz_burnFrom(uint256 amount) public {
        uint256 balance = coinGenieERC20.balanceOf(address(this));
        vm.assume(amount <= balance);
        uint256 totalSupplyBefore = coinGenieERC20.totalSupply();

        address to1 = address(0x1);
        coinGenieERC20.transfer(to1, amount);
        vm.prank(to1);
        coinGenieERC20.approve(address(this), amount);

        coinGenieERC20.burnFrom(to1, amount);

        assertEq(coinGenieERC20.totalSupply(), totalSupplyBefore - amount);
    }

    function test_pause() public {
        assertEq(coinGenieERC20.paused(), false);
        coinGenieERC20.pause();
        assertEq(coinGenieERC20.paused(), true);
    }

    function test_unpause() public {
        coinGenieERC20.pause();
        assertEq(coinGenieERC20.paused(), true);
        coinGenieERC20.unpause();
        assertEq(coinGenieERC20.paused(), false);
    }
}
