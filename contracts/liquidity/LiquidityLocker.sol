// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Migrator } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Migrator.sol";

contract LiquidityLocker is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public fee;
    address public feeRecipient;

    IUniswapV2Factory private constant _UNISWAP_V2_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    struct User {
        EnumerableSet.AddressSet lockedTokens;
        mapping(address => uint256[]) locksForToken;
    }

    struct TokenLock {
        uint256 lockDate;
        uint256 amount;
        uint256 initialAmount;
        uint256 unlockDate;
        uint256 lockID;
        address owner;
    }

    mapping(address userAddress => User user) private _users;

    EnumerableSet.AddressSet private _lockedTokens;
    mapping(address pair => TokenLock[] locks) public tokenLocks; // map univ2 pair to all its locks

    IUniswapV2Migrator public migrator;

    event FeeSet(uint256 indexed fee);
    event MigratorSet(address indexed migrator);
    event FeeRecipientSet(address indexed feeRecipient);
    event LockOwnershipTransfered(address indexed newOwner);
    event OnWithdraw(address indexed lpToken, uint256 indexed amount);
    event Migrated(address indexed user, address indexed lpToken, uint256 indexed amount);
    event OnRelock(address indexed user, address indexed lpToken, uint256 indexed unlockDate);
    event OnDeposit(
        address lpToken, address indexed user, uint256 amount, uint256 indexed lockDate, uint256 indexed unlockDate
    );

    error LockMismatch();
    error InvalidAmount();
    error MigratorNotSet();
    error InvalidLockDate();
    error OwnerAlreadySet();
    error InvalidRecipient();
    error BeforeUnlockDate();
    error NotUniPair(address lpToken);
    error TransferFailed(uint256 amount, address from, address to);

    constructor(uint256 _fee, address _feeRecipient) payable {
        fee = _fee;
        feeRecipient = _feeRecipient;
    }

    function setFee(uint256 amount) external onlyOwner {
        fee = amount;
        emit FeeSet(amount);
    }

    function setFeeRecipient(address feeRecipient_) external onlyOwner {
        feeRecipient = feeRecipient_;
        emit FeeRecipientSet(feeRecipient_);
    }

    function setMigrator(IUniswapV2Migrator _migrator) external onlyOwner {
        migrator = _migrator;
        emit MigratorSet(address(_migrator));
    }

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
        if (msg.value < fee) {
            revert InvalidAmount();
        }

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

        SafeERC20.safeTransferFrom(lpToken, _msgSender(), address(this), amountOfLPToLock);

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

        (bool success,) = feeRecipient.call{ value: msg.value }("");
        if (!success) {
            revert TransferFailed(msg.value, address(this), feeRecipient);
        }

        emit OnDeposit(address(lpToken), _msgSender(), tokenLock.amount, tokenLock.lockDate, tokenLock.unlockDate);
    }

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
        emit OnRelock(_msgSender(), address(_lpToken), _unlockDate);
    }

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

        SafeERC20.safeTransfer(_lpToken, _msgSender(), _amount);
        emit OnWithdraw(address(_lpToken), _amount);
    }

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

        SafeERC20.safeTransferFrom(_lpToken, address(_msgSender()), address(this), _amount);

        userLock.amount = userLock.amount + _amount;

        emit OnDeposit(address(_lpToken), _msgSender(), userLock.amount, userLock.lockDate, userLock.unlockDate);

        return userLock;
    }

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
        emit LockOwnershipTransfered(_newOwner);
    }

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
        emit Migrated(_msgSender(), address(_lpToken), _amount);
    }

    function getNumLocksForToken(address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }

    function getNumLockedTokens() external view returns (uint256) {
        return _lockedTokens.length();
    }

    function getLockedTokenAtIndex(uint256 _index) external view returns (address) {
        return _lockedTokens.at(_index);
    }

    function getUserNumLockedTokens(address _user) external view returns (uint256) {
        User storage user = _users[_user];
        return user.lockedTokens.length();
    }

    function getUserLockedTokenAtIndex(address _user, uint256 _index) external view returns (address) {
        User storage user = _users[_user];
        return user.lockedTokens.at(_index);
    }

    function getUserNumLocksForToken(address _user, address _lpToken) external view returns (uint256) {
        User storage user = _users[_user];
        return user.locksForToken[_lpToken].length;
    }

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
