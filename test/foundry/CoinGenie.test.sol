// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { CoinGenie } from "../../contracts/CoinGenie.sol";

import { TokenTracker } from "../../contracts/tokens/TokenTracker.sol";
import { TokenFactory } from "../../contracts/tokens/TokenFactory.sol";
import { ITokenTracker } from "../../contracts/tokens/ITokenTracker.sol";
import { ITokenFactory } from "../../contracts/tokens/ITokenFactory.sol";
import { CoinGenieERC20 } from "../../contracts/tokens/CoinGenieERC20.sol";
import { ICoinGenieERC20 } from "../../contracts/tokens/ICoinGenieERC20.sol";

import { LiquidityRaiseFactory } from "../../contracts/liquidity/LiquidityRaiseFactory.sol";
import { ILiquidityRaiseFactory } from "../../contracts/liquidity/ILiquidityRaiseFactory.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract CoinGenieTest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant MAX_TAX = 2000;
    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant COIN_GENIE_FEE = 100;

    CoinGenie public coinGenie;
    MockERC20 public mockERC20;
    ICoinGenieERC20 public coinGenieERC20;
    ITokenFactory public erc20Factory;
    ILiquidityRaiseFactory public liquidityRaiseFactory;

    ITokenTracker.LaunchTokenParams public launchTokenParams;

    struct CoinGenieClaimableAirdrop {
        address airdropAddress;
        address tokenOwner;
        address airdropTokenAddress;
        uint256 airdropAmount;
        uint256 expirationTimestamp;
        uint256 maxWalletClaimCount;
        bytes32 merkleRoot;
    }

    event CoinGenieClaimableAirdropCreated(
        address indexed airdropAddress,
        address tokenOwner,
        address indexed airdropTokenAddress,
        uint256 indexed airdropAmount,
        uint256 expirationTimestamp,
        uint256 maxWalletClaimCount,
        bytes32 merkleRoot
    );

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    function setUp() public {
        mockERC20 = new MockERC20("MockERC20", "MOCK", 18);
        mockERC20.mint(address(this), MAX_TOKEN_SUPPLY);

        erc20Factory = new TokenFactory();
        liquidityRaiseFactory = new LiquidityRaiseFactory();

        coinGenie =
            new CoinGenie(address(erc20Factory), address(liquidityRaiseFactory), ICoinGenieERC20(address(mockERC20)));
        coinGenieERC20 = coinGenie.launchToken(
            ITokenTracker.LaunchTokenParams({
                name: "Coin Genie",
                symbol: "COIN",
                feeRecipient: payable(address(this)),
                affiliateFeeRecipient: payable(address(this)),
                totalSupply: MAX_TOKEN_SUPPLY,
                taxPercent: 500,
                maxBuyPercent: MAX_BPS,
                maxWalletPercent: MAX_BPS
            })
        );

        launchTokenParams = ITokenTracker.LaunchTokenParams({
            name: coinGenieERC20.name(),
            symbol: coinGenieERC20.symbol(),
            feeRecipient: coinGenieERC20.feeRecipient(),
            affiliateFeeRecipient: coinGenieERC20.affiliateFeeRecipient(),
            totalSupply: coinGenieERC20.totalSupply(),
            taxPercent: coinGenieERC20.taxPercent(),
            maxBuyPercent: coinGenieERC20.maxBuyPercent(),
            maxWalletPercent: coinGenieERC20.maxWalletPercent()
        });
    }

    function test_genie() public {
        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(address(token.genie()), address(coinGenieERC20), "Genie address is not correct");
    }

    function testFuzz_launchToken_name(string memory name) public {
        launchTokenParams.name = name;
        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.name(), name, "Name is not correct");
    }

    function testFuzz_launchToken_symbol(string memory symbol) public {
        launchTokenParams.symbol = symbol;
        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.symbol(), symbol, "Symbol is not correct");
    }

    function testFuzz_launchToken_totalSupply(uint256 totalSupply) public {
        vm.assume(totalSupply > 1 ether);
        vm.assume(totalSupply <= MAX_TOKEN_SUPPLY);
        launchTokenParams.totalSupply = totalSupply;

        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.totalSupply(), totalSupply, "Total supply is not correct");
    }

    function testFuzz_launchToken_affiliateFeeRecipient(address payable affiliateFeeRecipient) public {
        vm.assume(affiliateFeeRecipient != address(0));
        launchTokenParams.affiliateFeeRecipient = affiliateFeeRecipient;

        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.affiliateFeeRecipient(), affiliateFeeRecipient, "Affiliate fee recipient is not correct");
    }

    function test_launchToken_affiliateFeeRecipient_zeroAddress() public {
        launchTokenParams.affiliateFeeRecipient = payable(address(0));
        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.affiliateFeeRecipient(), address(coinGenie), "Affiliate fee recipient is not correct");
    }

    function testFuzz_launchToken_taxPercent(uint256 taxPercent) public {
        vm.assume(taxPercent <= MAX_TAX);
        launchTokenParams.taxPercent = taxPercent;

        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.taxPercent(), taxPercent, "Tax percent is not correct");
    }

    function testFuzz_launchToken_maxBuyPercent(uint256 maxBuyPercent) public {
        vm.assume(maxBuyPercent <= MAX_TAX);
        launchTokenParams.maxBuyPercent = maxBuyPercent;

        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.maxBuyPercent(), maxBuyPercent, "Max buy percent is not correct");
    }

    function testFuzz_launchToken_maxWalletPercent(uint256 maxWalletPercent) public {
        vm.assume(maxWalletPercent <= MAX_TAX);
        launchTokenParams.maxWalletPercent = maxWalletPercent;

        ICoinGenieERC20 token = coinGenie.launchToken(launchTokenParams);

        assertEq(token.maxWalletPercent(), maxWalletPercent, "Max wallet percent is not correct");
    }

    function test_getNumberOfLaunchedTokens() public {
        assertEq(coinGenie.getNumberOfLaunchedTokens(), 1, "Number of launched tokens is not correct - 1");

        coinGenie.launchToken(launchTokenParams);

        assertEq(coinGenie.getNumberOfLaunchedTokens(), 2, "Number of launched tokens is not correct - 2");
    }

    function test_getLaunchedTokensForAddress() public {
        ICoinGenieERC20 tokenDetails = coinGenie.launchToken(launchTokenParams);

        CoinGenie.TokenDetails[] memory launchedTokenStruct = coinGenie.getLaunchedTokensForAddress(address(this));
        uint256 launchedTokenStructLength = launchedTokenStruct.length;
        CoinGenie.TokenDetails memory launchedTokenStructLast = launchedTokenStruct[launchedTokenStructLength - 1];

        assertEq(launchedTokenStructLast.tokenAddress, address(tokenDetails), "Token address is not correct");
    }

    function testFuzz_setDiscountPercent(uint256 discountPercent) public {
        vm.assume(discountPercent <= MAX_BPS);
        coinGenie.setDiscountPercent(discountPercent);
        assertEq(coinGenie.discountPercent(), discountPercent, "Discount percent is not correct");
    }

    function testFail_setDiscountPercent() public {
        coinGenie.setDiscountPercent(MAX_BPS + 1);
    }

    function testFuzz_setDiscountFeeRequiredAmount(uint256 discountAmount) public {
        coinGenie.setDiscountFeeRequiredAmount(discountAmount);
        assertEq(coinGenie.discountFeeRequiredAmount(), discountAmount, "Discount fee required amount is not correct");
    }

    // TODO: write this test
    function test_affiliateRelease() public { }

    function testFuzz_setAffiliatePercent(uint256 affiliateFeePercent) public {
        vm.assume(affiliateFeePercent <= MAX_BPS);
        coinGenie.setAffiliatePercent(affiliateFeePercent);
        assertEq(coinGenie.affiliateFeePercent(), affiliateFeePercent, "Affiliate fee percent is not correct");
    }

    function testFail_setAffiliatePercent() public {
        coinGenie.setAffiliatePercent(MAX_BPS + 1);
    }

    // TODO: write this test
    function test_release() public { }

    function test_updateSplit() public {
        address[] memory payees = new address[](4);
        uint256[] memory shares = new uint256[](4);
        payees[0] = address(1); // treasury
        payees[1] = address(2); // dev
        payees[2] = address(3); // marketing
        payees[3] = address(4); // legal

        shares[0] = 10;
        shares[1] = 20;
        shares[2] = 30;
        shares[3] = 40;

        coinGenie.updateSplit(payees, shares);

        uint256 len = payees.length;
        for (uint256 i = 0; i < len; i++) {
            assertEq(coinGenie.payee(i), payees[i], "Payee not correct");
            assertEq(coinGenie.shares(payees[i]), shares[i], "Shares are not correct");
        }
    }

    function test_swapGenieForEth() public {
        uint256 amount = coinGenieERC20.balanceOf(address(this)) / 2;
        coinGenieERC20.createPairAndAddLiquidity{ value: 0.5 ether }(amount, false);
        coinGenieERC20.transfer(address(coinGenie), amount);
        coinGenie.swapGenieForEth(amount);
        assertEq(coinGenieERC20.balanceOf(address(coinGenie)), 0, "Balance is not correct");
    }
}
