// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { EnumerableSet } from "openzeppelin/utils/structs/EnumerableSet.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { SafeMath } from "openzeppelin/utils/math/SafeMath.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";

import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Migrator } from "v2-periphery/interfaces/IUniswapV2Migrator.sol";

import { SafeTransfer } from "./lib/SafeTransfer.sol";

/**
 * @title LiquidityLocker
 * @author @neuro_0x
 * @dev A contract for locking Uniswap V2 liquidity pool tokens for specified periods.
 */
contract LiquidityLocker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    error InvalidAmount();
    error InvalidLockDate();
    error LockMismatch();
    error BeforeUnlockDate();
    error OwnerAlreadySet();
    error MigratorNotSet();
    error NotUniPair(address lpToken);

    IUniswapV2Factory private constant _UNISWAP_V2_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    struct User {
        EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
    }

    struct TokenLock {
        uint256 lockDate; // the date the token was locked
        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 initialAmount; // the initial lock amount
        uint256 unlockDate; // the date the token can be withdrawn
        uint256 lockID; // lockID nonce per uni pair
        address owner;
    }

    mapping(address userAddress => User user) private _users;

    EnumerableSet.AddressSet private _lockedTokens;
    mapping(address pair => TokenLock[] locks) public tokenLocks; // map univ2 pair to all its locks

    IUniswapV2Migrator public migrator;

    event OnWithdraw(address lpToken, uint256 amount);
    event OnDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);

    /**
     * @dev Set the migrator contract which allows locked lp tokens to be migrated to uniswap v3
     * @param _migrator The address of the migrator contract
     */
    function setMigrator(IUniswapV2Migrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    /**
     * @dev Creates a new lock
     * @param lpToken the univ2 token address
     * @param amountOfLPToLock amount of LP tokens to lock
     * @param unlockDate the unix timestamp (in seconds) until unlock
     * @param withdrawer the user who can withdraw liquidity once the lock expires
     */
    function lockLPToken(
        IERC20 lpToken,
        uint256 amountOfLPToLock,
        uint256 unlockDate,
        address payable withdrawer
    )
        external
        payable
        nonReentrant
        returns (TokenLock memory tokenLock)
    {
        if (amountOfLPToLock == 0) {
            revert InvalidAmount();
        }

        if (unlockDate > 10_000_000_000) {
            revert InvalidLockDate();
        }

        // ensure this pair is a univ2 pair by querying the factory
        IUniswapV2Pair lpair = IUniswapV2Pair(address(lpToken));
        address factoryPairAddress = _UNISWAP_V2_FACTORY.getPair(lpair.token0(), lpair.token1());

        if (factoryPairAddress != address(lpToken)) {
            revert NotUniPair(address(lpToken));
        }

        SafeTransfer.safeTransferFrom(address(lpToken), _msgSender(), address(this), amountOfLPToLock);

        tokenLock.lockDate = block.timestamp;
        tokenLock.amount = amountOfLPToLock;
        tokenLock.initialAmount = amountOfLPToLock;
        tokenLock.unlockDate = unlockDate;
        tokenLock.lockID = tokenLocks[address(lpToken)].length;
        tokenLock.owner = withdrawer;

        // record the lock for the univ2pair
        tokenLocks[address(lpToken)].push(tokenLock);
        _lockedTokens.add(address(lpToken));

        // record the lock for the user
        User storage user = _users[withdrawer];
        user.lockedTokens.add(address(lpToken));
        uint256[] storage userLocks = user.locksForToken[address(lpToken)];
        userLocks.push(tokenLock.lockID);

        emit OnDeposit(address(lpToken), _msgSender(), tokenLock.amount, tokenLock.lockDate, tokenLock.unlockDate);
    }

    /**
     * @dev extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
     * @param _lpToken the univ2 token address
     * @param _index the index of the lock for the token
     * @param _lockID the lockID of the lock for the token
     * @param _unlockDate the new unix timestamp (in seconds) until unlock
     */
    function relock(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _unlockDate) external nonReentrant {
        if (_unlockDate > 10_000_000_000) {
            revert InvalidLockDate();
        }

        // timestamp entered in seconds
        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        if (userLock.unlockDate > _unlockDate) {
            revert BeforeUnlockDate();
        }

        userLock.unlockDate = _unlockDate;
    }

    /**
     * @dev withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
     */
    function withdraw(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        if (userLock.unlockDate > block.timestamp) {
            revert BeforeUnlockDate();
        }

        userLock.amount = userLock.amount - _amount;

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = _users[_msgSender()].locksForToken[address(_lpToken)];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            if (userLocks.length == 0) {
                _users[_msgSender()].lockedTokens.remove(address(_lpToken));
            }
        }

        SafeTransfer.safeTransfer(address(_lpToken), _msgSender(), _amount);
        emit OnWithdraw(address(_lpToken), _amount);
    }

    /**
     * @dev increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees,
     * and faster loading on our live block explorer
     */
    function incrementLock(
        IERC20 _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    )
        external
        nonReentrant
        returns (TokenLock memory _userLock)
    {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        SafeTransfer.safeTransferFrom(address(_lpToken), address(_msgSender()), address(this), _amount);

        userLock.amount = userLock.amount + _amount;

        emit OnDeposit(address(_lpToken), _msgSender(), userLock.amount, userLock.lockDate, userLock.unlockDate);

        return userLock;
    }

    /**
     * @dev transfer a lock to a new owner, e.g. presale project -> project owner
     */
    function transferLockOwnership(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        address payable _newOwner
    )
        external
    {
        if (_newOwner == owner()) {
            revert OwnerAlreadySet();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[_lpToken][_index];
        TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];

        if (lockID != _lockID || transferredLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        // record the lock for the new Owner
        User storage user = _users[_newOwner];
        user.lockedTokens.add(_lpToken);

        uint256[] storage userLocks = user.locksForToken[_lpToken];
        userLocks.push(transferredLock.lockID);

        // remove the lock from the old owner
        uint256[] storage userLocks2 = _users[_msgSender()].locksForToken[_lpToken];
        userLocks2[_index] = userLocks2[userLocks2.length - 1];
        userLocks2.pop();

        if (userLocks2.length == 0) {
            _users[_msgSender()].lockedTokens.remove(_lpToken);
        }

        transferredLock.owner = _newOwner;
    }

    /**
     * @dev migrates liquidity to uniswap v3
     */
    function migrate(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        if (address(migrator) == address(0)) {
            revert MigratorNotSet();
        }

        if (_amount == 0) {
            revert InvalidAmount();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        userLock.amount = userLock.amount - _amount;

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = _users[_msgSender()].locksForToken[address(_lpToken)];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            if (userLocks.length == 0) {
                _users[_msgSender()].lockedTokens.remove(address(_lpToken));
            }
        }

        IERC20(_lpToken).approve(address(migrator), _amount);
        migrator.migrate(address(_lpToken), _amount, userLock.unlockDate, _msgSender(), block.timestamp + 1 days);
    }

    /**
     * @dev Get the number of locks for a specific token.
     * @param _lpToken The address of the LP token.
     */
    function getNumLocksForToken(address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }

    /**
     * @dev Get the total number of locked tokens
     */
    function getNumLockedTokens() external view returns (uint256) {
        return _lockedTokens.length();
    }

    /**
     * @dev Get the address of a locked token at an index.
     * @param _index The index of the token.
     */
    function getLockedTokenAtIndex(uint256 _index) external view returns (address) {
        return _lockedTokens.at(_index);
    }

    /**
     * @dev Get the number of tokens a user has locked.
     * @param _user The address of the user.
     */
    function getUserNumLockedTokens(address _user) external view returns (uint256) {
        User storage user = _users[_user];
        return user.lockedTokens.length();
    }

    /**
     * @dev Get the token address a user has locked at an index.
     * @param _user The address of the user.
     * @param _index The index of the token.
     */
    function getUserLockedTokenAtIndex(address _user, uint256 _index) external view returns (address) {
        User storage user = _users[_user];
        return user.lockedTokens.at(_index);
    }

    /**
     * @dev Get the number of locks for a specific user and token.
     * @param _user The address of the user.
     * @param _lpToken The address of the LP token.
     */
    function getUserNumLocksForToken(address _user, address _lpToken) external view returns (uint256) {
        User storage user = _users[_user];
        return user.locksForToken[_lpToken].length;
    }

    /**
     * @dev Get the lock for a specific user and token at an index.
     * @param _user The address of the user.
     * @param _lpToken The address of the LP token.
     * @param _index The index of the lock.
     * @return The lock date.
     * @return Amount of tokens locked.
     * @return Initial amount of tokens locked.
     * @return Unlock date of the lock.
     * @return Lock ID of the lock.
     * @return Owner of the lock.
     */
    function getUserLockForTokenAtIndex(
        address _user,
        address _lpToken,
        uint256 _index
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address)
    {
        uint256 lockID = _users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (
            tokenLock.lockDate,
            tokenLock.amount,
            tokenLock.initialAmount,
            tokenLock.unlockDate,
            tokenLock.lockID,
            tokenLock.owner
        );
    }
}
