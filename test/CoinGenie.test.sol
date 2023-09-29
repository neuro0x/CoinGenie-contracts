// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "../lib/forge-std/src/Test.sol";

import { IUniswapV2Pair } from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { CoinGenie } from "../src/CoinGenie.sol";
import { ICoinGenieERC20 } from "../src/interfaces/ICoinGenieERC20.sol";
import { ERC20Factory } from "../src/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../src/AirdropERC20ClaimableFactory.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract CoinGenieTest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    uint256 public constant MAX_TAX = 2000;
    uint256 public constant MAX_BPS = 10_000;

    CoinGenie public coinGenie;
    MockERC20 public mockERC20;
    ICoinGenieERC20 public coinGenieERC20;
    ERC20Factory public coinGenieERC20Factory;
    AirdropERC20ClaimableFactory public coinGenieAirdropFactory;

    struct LaunchToken {
        string name;
        string symbol;
        uint256 totalSupply;
        address payable feeRecipient;
        address payable affiliateFeeRecipient;
        uint256 taxPercent;
        uint256 deflationPercent;
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
        deflationPercent: 1000,
        maxBuyPercent: 500,
        maxWalletPercent: 500
    });

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

        coinGenieERC20Factory = new ERC20Factory();
        coinGenieAirdropFactory = new AirdropERC20ClaimableFactory();
        coinGenie = new CoinGenie(address(coinGenieERC20Factory), address(coinGenieAirdropFactory));
        coinGenieERC20 = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        coinGenieERC20Factory.setGenie(address(coinGenieERC20));
        coinGenieERC20.setGenie(payable(address(coinGenieERC20)));
    }

    function testFuzz_launchToken_name(string memory name) public {
        coinGenie.launchToken(
            name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_symbol(string memory symbol) public {
        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_symbol(uint256 totalSupply) public {
        vm.assume(totalSupply > 0);
        vm.assume(totalSupply <= MAX_TOKEN_SUPPLY);

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_feeRecipient(address payable feeRecipient) public {
        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_affiliateFeeRecipient(address payable affiliateFeeRecipient) public {
        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_taxPercent(uint256 taxPercent) public {
        vm.assume(taxPercent <= MAX_TAX);

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_deflationPercent(uint256 deflationPercent) public {
        vm.assume(deflationPercent <= MAX_TAX);

        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_maxBuyPercent(uint256 maxBuyPercent) public {
        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );
    }

    function testFuzz_launchToken_maxWalletPercent(uint256 maxWalletPercent) public {
        coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            maxWalletPercent
        );
    }

    function test_getLaunchedTokensForAddress() public {
        ICoinGenieERC20 launchedToken = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.feeRecipient,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.deflationPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        CoinGenie.LaunchedToken[] memory launchedTokenStruct = coinGenie.getLaunchedTokensForAddress(address(this));
        uint256 launchedTokenStructLength = launchedTokenStruct.length;
        CoinGenie.LaunchedToken memory launchedTokenStructLast = launchedTokenStruct[launchedTokenStructLength - 1];

        assertEq(launchedTokenStructLast.tokenAddress, address(launchedToken));
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
