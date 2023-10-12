// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
            ██████                                                                                  
           ████████         █████████     ██████████     ███  ████         ███                      
            ██████        █████████████ ██████████████   ████ ██████      ████                      
              ██        ████████  ████ ██████    ██████  ████ ███████     ████                      
              ██       █████          █████        █████ ████ █████████   ████                      
              ██       █████          ████         █████ ████ ████ ██████ ████                      
             ████      █████          ████         █████ ████ ████  ██████████                      
            █████       █████         █████        █████ ████ ████    ████████                      
           ████████      █████████████ ████████████████  ████ ████     ███████                      
          ████  ████      █████████████  ████████████    ████ ████       █████                      
        █████    █████        █████          ████                                                   
      ██████      ██████                                                                            
    ██████         ███████                                                                          
  ████████          ████████           ███████████  █████████████████        ████  ████ ████████████
 ████████           █████████        █████████████  ███████████████████      ████ █████ ████████████
█████████           ██████████     ███████          █████        ████████    ████ █████ ████        
██████████         ████████████    █████            █████        █████████   ████ █████ ████        
██████████████   ██████████████    █████   ████████ ████████████ ████ ██████ ████ █████ ███████████ 
███████████████████████████████    █████   ████████ ██████████   ████  ██████████ █████ ██████████  
███████████████████████████████    ██████      ████ █████        ████    ████████ █████ ████        
 █████████████████████████████      ███████████████ ████████████ ████      ██████ █████ ████████████
  ██████████████████████████          █████████████ █████████████████       █████ █████ ████████████
 */

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title AirdropERC20Claimable
 * @author @neuro_0x
 * @dev A contract for airdropping ERC20 tokens to specific recipients based on Merkle proofs.
 */

contract AirdropERC20Claimable {
    error InvalidTransferAmount();
    error AirdropExpired();
    error AlreadyClaimedMax();
    error TransferFailed();
    error InvalidAirdropParameters(address tokenOwner, address airdropTokenAddress, uint256 airdropAmount);

    /// @dev The address of the token to be airdropped.
    address public immutable airdropTokenAddress;

    /// @dev The owner of the token to be airdropped.
    address public immutable tokenOwner;

    /// @dev Expiration timestamp of the airdrop.
    uint256 public immutable expirationTimestamp;

    /// @dev Maximum number of tokens that can be claimed by a wallet if not in the whitelist.
    uint256 public immutable maxWalletClaimCount;

    /// @dev Merkle root of the whitelist.
    bytes32 public immutable merkleRoot;

    /// @dev The quantity of tokens available for airdrop.
    uint256 public availableAmount;

    /// @dev Mapping from address => total number of tokens a wallet has claimed.
    mapping(address claimer => uint256 amount) public totalClaimedByWallet;

    /// @dev Emitted when tokens are claimed
    event TokensClaimed(address indexed claimer, uint256 indexed quantityClaimed);

    /**
     * @dev Initializes the contract.
     * @param _tokenOwner The owner of the token to be airdropped.
     * @param _airdropTokenAddress The address of the token to be airdropped.
     * @param _airdropAmount The quantity of tokens available for airdrop.
     * @param _expirationTimestamp Expiration timestamp of the airdrop.
     * @param _maxWalletClaimCount Maximum number of tokens that can be claimed by a wallet if not in the whitelist.
     * @param _merkleRoot Merkle root of the whitelist.
     */
    constructor(
        address _tokenOwner,
        address _airdropTokenAddress,
        uint256 _airdropAmount,
        uint256 _expirationTimestamp,
        uint256 _maxWalletClaimCount,
        bytes32 _merkleRoot
    )
        payable
    {
        if (_tokenOwner == address(0) || _airdropTokenAddress == address(0) || _airdropAmount == 0) {
            revert InvalidAirdropParameters(_tokenOwner, _airdropTokenAddress, _airdropAmount);
        }

        tokenOwner = _tokenOwner;
        airdropTokenAddress = _airdropTokenAddress;
        availableAmount = _airdropAmount;
        expirationTimestamp = _expirationTimestamp;
        maxWalletClaimCount = _maxWalletClaimCount;
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Claims tokens from the airdrop.
     * @param amount The quantity of tokens to claim.
     * @param proofs Claims proofs.
     * @param proofMaxQuantityForWallet The maximum quantity of tokens that can be claimed by a wallet.
     */
    function claim(uint256 amount, bytes32[] calldata proofs, uint256 proofMaxQuantityForWallet) external {
        // Verify the claim
        verifyClaim(msg.sender, amount, proofs, proofMaxQuantityForWallet);
        // Transfer the claimed tokens
        _transferClaimedTokens(msg.sender, amount);
        // Emit the TokensClaimed event
        emit TokensClaimed(msg.sender, amount);
    }

    /**
     * @dev Verifies the claim and reverts if the claim is invalid.
     * @param claimant The address of the claimer.
     * @param amount The quantity of tokens to claim.
     * @param proofs Claims proofs.
     * @param proofMaxQuantityForWallet The maximum quantity of tokens that can be claimed by a wallet.
     */
    function verifyClaim(
        address claimant,
        uint256 amount,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityForWallet
    )
        public
        view
    {
        bool verified;
        // Get the proof of the claimer
        if (merkleRoot != bytes32(0)) {
            verified =
                MerkleProof.verify(proofs, merkleRoot, keccak256(abi.encodePacked(claimant, proofMaxQuantityForWallet)));
        }

        // Check if the wallet has already claimed tokens
        uint256 supplyClaimedAlready = totalClaimedByWallet[claimant];

        // Check if the claim is valid
        if (amount == 0 || amount > availableAmount) {
            revert InvalidTransferAmount();
        }

        // Check if the airdrop has expired
        uint256 expTimestamp = expirationTimestamp;
        if (expTimestamp != 0 && block.timestamp >= expTimestamp) {
            revert AirdropExpired();
        }

        // Check if the wallet has exceeded the maximum number of tokens that can be claimed
        uint256 claimLimitForWallet = verified ? proofMaxQuantityForWallet : maxWalletClaimCount;
        if (amount + supplyClaimedAlready > claimLimitForWallet) {
            revert AlreadyClaimedMax();
        }
    }

    /**
     * @dev Transfers the claimed tokens to the recipient.
     * @param recipient The recipient of the tokens.
     * @param amount The quantity of tokens to claim.
     */
    function _transferClaimedTokens(address recipient, uint256 amount) private {
        // if transfer claimed tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_recipient`.
        totalClaimedByWallet[msg.sender] += amount;
        availableAmount -= amount;

        IERC20 airdropToken = IERC20(airdropTokenAddress);
        if (!airdropToken.transfer(recipient, amount)) {
            revert TransferFailed();
        }
        require(airdropToken.transferFrom(tokenOwner, recipient, amount), "Transfer failed");
    }
}
