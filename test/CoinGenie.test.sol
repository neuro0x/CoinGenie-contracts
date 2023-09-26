// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// solhint-disable-next-line no-global-import
import "../lib/forge-std/src/Test.sol";

import { IUniswapV2Pair } from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { CoinGenie } from "../src/CoinGenie.sol";
import { CoinGenieERC20 } from "../src/CoinGenieERC20.sol";
import { ERC20Factory } from "../src/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../src/AirdropERC20ClaimableFactory.sol";
import { Common } from "../src/lib/Common.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract CoinGenieTest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant MAX_TAX = 2000;
    uint256 public constant MAX_BPS = 10_000;

    CoinGenie public coinGenie;
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
    fallback() external payable { }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable { }

    function setUp() public {
        coinGenie = new CoinGenie(address(new ERC20Factory()), address(new AirdropERC20ClaimableFactory()));
        mockERC20 = new MockERC20("Mock", "MOCK", 18);

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

        mockERC20.mint(address(this), MAX_TOKEN_SUPPLY);
    }

    function testFuzz_launchToken_name(string memory name) public {
        coinGenie.launchToken(
            name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_symbol(string memory symbol) public {
        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            symbol,
            coinGenieLaunchToken.initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_initialSupply(uint256 initialSupply) public {
        vm.assume(initialSupply <= MAX_TOKEN_SUPPLY);

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_tokenOwner(address tokenOwner) public {
        vm.assume(tokenOwner != address(0));

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.initialSupply,
            tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_maxTokenAmount(uint256 maxPerWallet) public {
        vm.assume(maxPerWallet <= MAX_TOKEN_SUPPLY);
        vm.assume(maxPerWallet > 0);

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_autoWithdrawThreshold(uint256 autoWithdrawThreshold) public {
        vm.assume(autoWithdrawThreshold <= 1000);
        vm.assume(autoWithdrawThreshold > 0);

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
        );
    }

    function testFuzz_launchToken_maxTaxSwap(uint256 maxTaxSwap) public {
        vm.assume(maxTaxSwap <= MAX_TOKEN_SUPPLY);
        vm.assume(maxTaxSwap > 0);

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
        );
    }

    function testFuzz_launchToken_affiliateFeeRecipient(address affiliateFeeRecipient) public {
        vm.assume(affiliateFeeRecipient != address(0));

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_feeRecipient(address feeRecipient) public {
        vm.assume(feeRecipient != address(0));

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            feeRecipient,
            coinGenieLaunchToken.feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_feePercentage(uint256 feePercentage) public {
        vm.assume(feePercentage <= MAX_TAX);

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.initialSupply,
            coinGenieLaunchToken.tokenOwner,
            coinGenieLaunchToken.customConfigProps,
            coinGenieLaunchToken.maxPerWallet,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.feeRecipient,
            feePercentage,
            coinGenieLaunchToken.burnPercentage
        );
    }

    function testFuzz_launchToken_burnPercentage(uint256 burnPercentage) public {
        vm.assume(burnPercentage <= MAX_TAX);

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
            burnPercentage
        );
    }

    function testFuzz_createClaimableAirdrop_airdropAmount(
        uint256 airdropAmount,
        uint8 maxWalletClaimCount,
        bytes32 merkleRoot
    )
        public
    {
        vm.assume(airdropAmount > 0);
        vm.assume(airdropAmount <= MAX_TOKEN_SUPPLY);

        coinGenie.createClaimableAirdrop(
            address(this), address(mockERC20), airdropAmount, block.timestamp + 1 days, maxWalletClaimCount, merkleRoot
        );
    }

    function test_updatePayout() public {
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Treasury, payable(address(this)), 2000);
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Dev, payable(address(this)), 5000);
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Legal, payable(address(this)), 1500);
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Marketing, payable(address(this)), 1500);

        assertEq(coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Treasury), address(this));
        assertEq(coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Dev), address(this));
        assertEq(coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Legal), address(this));
        assertEq(coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Marketing), address(this));

        assertEq(coinGenie.getPayoutShare(CoinGenie.PayoutCategory.Treasury), 2000);
        assertEq(coinGenie.getPayoutShare(CoinGenie.PayoutCategory.Dev), 5000);
        assertEq(coinGenie.getPayoutShare(CoinGenie.PayoutCategory.Legal), 1500);
        assertEq(coinGenie.getPayoutShare(CoinGenie.PayoutCategory.Marketing), 1500);
    }

    function testFail_updatePayout_Treasury() public {
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Treasury, payable(address(this)), 2001);
    }

    function testFail_updatePayout_Dev() public {
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Dev, payable(address(this)), 5001);
    }

    function testFail_updatePayout_Legal() public {
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Legal, payable(address(this)), 1501);
    }

    function testFail_updatePayout_Marketing() public {
        coinGenie.updatePayout(CoinGenie.PayoutCategory.Marketing, payable(address(this)), 1501);
    }

    function test_withdraw() public {
        vm.deal(address(this), 1 ether);
        vm.deal(address(coinGenie), 1 ether);

        address treasuryAddress = coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Treasury);
        address devAddress = coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Dev);
        address legalAddress = coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Legal);
        address marketingAddress = coinGenie.getPayoutAddress(CoinGenie.PayoutCategory.Marketing);

        uint256 coinGenieBalanceBefore = address(coinGenie).balance;
        uint256 treasuryBalanceBefore = treasuryAddress.balance;
        uint256 devBalanceBefore = devAddress.balance;
        uint256 legalBalanceBefore = legalAddress.balance;
        uint256 marketingBalanceBefore = marketingAddress.balance;

        coinGenie.withdraw();

        assertLt(address(coinGenie).balance, coinGenieBalanceBefore);
        assertEq(treasuryAddress.balance, treasuryBalanceBefore + (1 ether * 2000) / 10_000);
        assertEq(devAddress.balance, devBalanceBefore + (1 ether * 5000) / 10_000);
        assertEq(legalAddress.balance, legalBalanceBefore + (1 ether * 1500) / 10_000);
        assertEq(marketingAddress.balance, marketingBalanceBefore + (1 ether * 1500) / 10_000);
    }

    function testFuzz_setQuoteThreshold(uint256 quoteThreshold) public {
        assertEq(coinGenie.quoteThreshold(), 0.1 ether);
        coinGenie.setQuoteThreshold(quoteThreshold);
        assertEq(coinGenie.quoteThreshold(), quoteThreshold);
    }

    function test_getLaunchedTokensForAddress() public {
        address launchedToken = coinGenie.launchToken(
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
        );

        CoinGenie.LaunchedToken[] memory launchedTokenStruct =
            coinGenie.getLaunchedTokensForAddress(coinGenieLaunchToken.tokenOwner);
        uint256 launchedTokenStructLength = launchedTokenStruct.length;
        CoinGenie.LaunchedToken memory launchedTokenStructLast = launchedTokenStruct[launchedTokenStructLength - 1];

        assertEq(launchedTokenStructLast.tokenAddress, launchedToken);
    }

    function test_getClaimableAirdropsForAddress() public {
        CoinGenieClaimableAirdrop memory coinGenieClaimableAirdrop = CoinGenieClaimableAirdrop({
            airdropAddress: address(0),
            tokenOwner: address(this),
            airdropTokenAddress: address(mockERC20),
            airdropAmount: 1000,
            expirationTimestamp: block.timestamp + 1 days,
            maxWalletClaimCount: 1,
            merkleRoot: bytes32(0)
        });

        address claimableAirdrop = coinGenie.createClaimableAirdrop(
            coinGenieClaimableAirdrop.tokenOwner,
            coinGenieClaimableAirdrop.airdropTokenAddress,
            coinGenieClaimableAirdrop.airdropAmount,
            coinGenieClaimableAirdrop.expirationTimestamp,
            coinGenieClaimableAirdrop.maxWalletClaimCount,
            coinGenieClaimableAirdrop.merkleRoot
        );

        CoinGenie.ClaimableAirdrop[] memory claimableAirdrops =
            coinGenie.getClaimableAirdropsForAddress(coinGenieClaimableAirdrop.tokenOwner);
        uint256 claimableAirdropsLength = claimableAirdrops.length;
        CoinGenie.ClaimableAirdrop memory claimableAirdropsLast = claimableAirdrops[claimableAirdropsLength - 1];

        assertEq(claimableAirdropsLast.airdropAddress, claimableAirdrop);
    }
}
