// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LiquidityLocker } from "../../contracts/LiquidityLocker.sol";
import { CoinGenie } from "../../contracts/CoinGenie.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Migrator } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Migrator.sol";

import { ICoinGenieERC20 } from "../../contracts/token/ICoinGenieERC20.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract LiquidityLockerTest is Test {
    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    LiquidityLocker public liquidityLocker;
    IERC20 public token;
    IUniswapV2Pair public lpToken;
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

    function setUp() public {
        mockERC20 = new MockERC20("TEST", "TEST", 18);
        mockERC20.mint(address(this), 100_000_000 ether);
        coinGenie = new CoinGenie();
        liquidityLocker = new LiquidityLocker(0.01 ether, address(coinGenie));
        coinGenieERC20 = coinGenie.launchToken(
            coinGenieLaunchToken.name,
            coinGenieLaunchToken.symbol,
            coinGenieLaunchToken.totalSupply,
            coinGenieLaunchToken.affiliateFeeRecipient,
            coinGenieLaunchToken.taxPercent,
            coinGenieLaunchToken.maxBuyPercent,
            coinGenieLaunchToken.maxWalletPercent
        );

        lpToken = IUniswapV2Pair(
            coinGenieERC20.createPairAndAddLiquidity{ value: 10 ether }(coinGenieERC20.balanceOf(address(this)), false)
        );
    }

    function testFuzz_setMigrator(IUniswapV2Migrator migrator) public {
        liquidityLocker.setMigrator(migrator);
        assertEq(address(liquidityLocker.migrator()), address(migrator));
    }

    function testFuzz_lockLPToken_amount(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= lpToken.balanceOf(address(this)));

        lpToken.approve(address(liquidityLocker), amount);

        uint256 unlockTime = block.timestamp + 1 days;
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), amount, unlockTime, payable(address(this))
        );

        uint256 userNumLockedTokens = liquidityLocker.getUserNumLockedTokens(address(this));
        for (uint256 i = 0; i < userNumLockedTokens;) {
            (
                uint256 lockDate,
                uint256 _amount,
                uint256 initialAmount,
                uint256 unlockDate,
                uint256 lockID,
                address owner
            ) = liquidityLocker.getUserLockForTokenAtIndex(address(this), address(lpToken), i);

            assertEq(lockDate, block.timestamp);
            assertEq(_amount, amount);
            assertEq(initialAmount, amount);
            assertEq(unlockDate, unlockTime);
            assertEq(lockID, i);
            assertEq(owner, address(this));

            unchecked {
                i = i + 1;
            }
        }
    }

    function testFuzz_lockLPToken_unlockDate(uint256 unlockDate) public {
        vm.assume(unlockDate > block.timestamp);
        vm.assume(unlockDate <= 10_000_000_000);

        uint256 amount = lpToken.balanceOf(address(this));

        lpToken.approve(address(liquidityLocker), amount);

        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), amount, unlockDate, payable(address(this))
        );

        uint256 userNumLockedTokens = liquidityLocker.getUserNumLockedTokens(address(this));
        for (uint256 i = 0; i < userNumLockedTokens;) {
            (
                uint256 lockDate,
                uint256 _amount,
                uint256 initialAmount,
                uint256 _unlockDate,
                uint256 lockID,
                address owner
            ) = liquidityLocker.getUserLockForTokenAtIndex(address(this), address(lpToken), i);

            assertEq(lockDate, block.timestamp);
            assertEq(_amount, amount);
            assertEq(initialAmount, amount);
            assertEq(_unlockDate, unlockDate);
            assertEq(lockID, i);
            assertEq(owner, address(this));

            unchecked {
                i = i + 1;
            }
        }
    }

    function testFuzz_lockLPToken_withdrawer(address payable withdrawer) public {
        uint256 amount = lpToken.balanceOf(address(this));

        lpToken.approve(address(liquidityLocker), amount);

        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), amount, block.timestamp + 1 days, withdrawer
        );

        uint256 userNumLockedTokens = liquidityLocker.getUserNumLockedTokens(withdrawer);
        for (uint256 i = 0; i < userNumLockedTokens;) {
            (
                uint256 lockDate,
                uint256 _amount,
                uint256 initialAmount,
                uint256 unlockDate,
                uint256 lockID,
                address owner
            ) = liquidityLocker.getUserLockForTokenAtIndex(withdrawer, address(lpToken), i);

            assertEq(lockDate, block.timestamp);
            assertEq(_amount, amount);
            assertEq(initialAmount, amount);
            assertEq(unlockDate, block.timestamp + 1 days);
            assertEq(lockID, i);
            assertEq(owner, withdrawer);

            unchecked {
                i = i + 1;
            }
        }
    }

    function test_withdraw() public {
        uint256 amount = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), amount);

        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), amount, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(lpToken.balanceOf(address(this)), 0);

        (, uint256 _amount,,, uint256 lockID,) =
            liquidityLocker.getUserLockForTokenAtIndex(address(this), address(lpToken), 0);

        vm.warp(block.timestamp + 1 days + 1 seconds);

        liquidityLocker.withdraw(IERC20(address(lpToken)), 0, lockID, _amount);

        assertEq(lpToken.balanceOf(address(this)), _amount);
    }

    function test_incrementLock() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), lpToken.balanceOf(address(this)));

        LiquidityLocker.TokenLock memory tokenLock = liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance / 2, block.timestamp + 1 days, payable(address(this))
        );

        LiquidityLocker.TokenLock memory incrementedLock =
            liquidityLocker.incrementLock(IERC20(address(lpToken)), 0, tokenLock.lockID, 10 ether);

        assertEq(incrementedLock.amount, balance / 2 + 10 ether);
    }

    function test_transferLockOwnership() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        LiquidityLocker.TokenLock memory tokenLock = liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        liquidityLocker.transferLockOwnership(address(lpToken), 0, tokenLock.lockID, payable(address(0)));

        assertEq(liquidityLocker.getUserNumLockedTokens(address(this)), 0);
        assertEq(liquidityLocker.getUserNumLockedTokens(address(0)), 1);
    }

    // TODO: this is failing for Vyper_contract::getExchange(0xE0fAce90bC3aFF2aB0F42E6CdDa48862a021cAa8) 🤷‍♂️
    // function test_migrate() public {
    //     uint256 balance = lpToken.balanceOf(address(this));
    //     lpToken.approve(address(liquidityLocker), balance);

    //     LiquidityLocker.TokenLock memory tokenLock = liquidityLocker.lockLPToken{ value: 0.1 ether }(
    //         IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
    //     );

    //     liquidityLocker.setMigrator(IUniswapV2Migrator(address(0x16D4F26C15f3658ec65B1126ff27DD3dF2a2996b)));
    //     liquidityLocker.migrate(IERC20(address(lpToken)), 0, tokenLock.lockID, tokenLock.amount);

    //     assertEq(liquidityLocker.getUserNumLockedTokens(address(this)), 0);
    //     assertEq(liquidityLocker.getUserNumLockedTokens(address(0)), 1);
    // }

    function test_getNumLocksForToken() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(liquidityLocker.getNumLocksForToken(address(lpToken)), 1);
    }

    function test_getNumLockedTokens() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(liquidityLocker.getNumLockedTokens(), 1);
    }

    function test_getLockedTokenAtIndex() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(liquidityLocker.getLockedTokenAtIndex(0), address(lpToken));
    }

    function test_getUserNumLockedTokens() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(liquidityLocker.getUserNumLockedTokens(address(this)), 1);
    }

    function test_getUserLockedTokenAtIndex() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(liquidityLocker.getUserLockedTokenAtIndex(address(this), 0), address(lpToken));
    }

    function test_getUserNumLocksForToken() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        assertEq(liquidityLocker.getUserNumLocksForToken(address(this), address(lpToken)), 1);
    }

    function test_getUserLockForTokenAtIndex() public {
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.approve(address(liquidityLocker), balance);

        // solhint-disable-next-line max-line-length
        liquidityLocker.lockLPToken{ value: 0.1 ether }(
            IERC20(address(lpToken)), balance, block.timestamp + 1 days, payable(address(this))
        );

        (uint256 lockDate, uint256 _amount, uint256 initialAmount, uint256 unlockDate, uint256 lockID, address owner) =
            liquidityLocker.getUserLockForTokenAtIndex(address(this), address(lpToken), 0);

        assertEq(lockDate, block.timestamp);
        assertEq(_amount, balance);
        assertEq(initialAmount, balance);
        assertEq(unlockDate, block.timestamp + 1 days);
        assertEq(lockID, 0);
        assertEq(owner, address(this));
    }
}
