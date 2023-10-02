// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";

import { CoinGenie } from "../../contracts/CoinGenie.sol";

import { ICoinGenieERC20 } from "../../contracts/token/ICoinGenieERC20.sol";
import { CoinGenieERC20 } from "../../contracts/token/CoinGenieERC20.sol";

import { ERC20Factory } from "../../contracts/factory/ERC20Factory.sol";
import { AirdropERC20ClaimableFactory } from "../../contracts/factory/AirdropERC20ClaimableFactory.sol";

contract ERC20FactoryTest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;

    CoinGenie public coinGenie;
    ICoinGenieERC20 public coinGenieERC20;
    ERC20Factory public erc20Factory;
    AirdropERC20ClaimableFactory public coinGenieAirdropFactory;

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
        erc20Factory = new ERC20Factory();
        coinGenieAirdropFactory = new AirdropERC20ClaimableFactory();

        coinGenie = new CoinGenie(address(erc20Factory), address(coinGenieAirdropFactory));

        coinGenieERC20 = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        erc20Factory.setGenie(address(coinGenieERC20));
        coinGenieERC20.setGenie(payable(address(coinGenieERC20)));
    }

    function test_launchToken() public {
        assertEq(coinGenieERC20.name(), coinGenieLaunchToken.name);
        assertEq(coinGenieERC20.symbol(), coinGenieLaunchToken.symbol);
        assertEq(coinGenieERC20.totalSupply(), coinGenieLaunchToken.totalSupply);
        assertEq(coinGenieERC20.feeRecipient(), coinGenieLaunchToken.feeRecipient);
        assertEq(coinGenieERC20.affiliateFeeRecipient(), coinGenieLaunchToken.affiliateFeeRecipient);
        assertEq(coinGenieERC20.taxPercent(), coinGenieLaunchToken.taxPercent);
        assertEq(coinGenieERC20.maxBuyPercent(), coinGenieLaunchToken.maxBuyPercent);
        assertEq(coinGenieERC20.maxWalletPercent(), coinGenieLaunchToken.maxWalletPercent);
    }
}
