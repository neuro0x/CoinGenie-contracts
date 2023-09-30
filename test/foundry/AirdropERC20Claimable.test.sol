// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {AirdropERC20Claimable} from "../../contracts/AirdropERC20Claimable.sol";

import {MockERC20} from "./mocks/ERC20.mock.sol";

contract AirdropERC20ClaimableTest is Test {
    using SafeMath for uint256;

    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;

    mapping(address user => uint256 balance) public balances;

    AirdropERC20Claimable public airdropContract;
    MockERC20 public mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock", "MOCK", 18);
        mockERC20.mint(address(this), MAX_TOKEN_SUPPLY);
        mockERC20 = new MockERC20("Mock", "MOCK", 18);
        mockERC20.mint(address(this), MAX_TOKEN_SUPPLY);
    }

    function testFuzz_constructor(uint256 amount, uint256 timestamp, uint256 claimCount, bytes32 merkleRoot) public {
        vm.assume(amount > 0);
        vm.assume(amount < MAX_TOKEN_SUPPLY);
        vm.assume(timestamp > block.timestamp);
        airdropContract = new AirdropERC20Claimable(
          address(this),
          address(mockERC20),
          amount,
          block.timestamp + 1 days,
          claimCount,
          merkleRoot
        );

        assertEq(airdropContract.airdropTokenAddress(), address(mockERC20), "airdropTokenAddress");
        assertEq(airdropContract.tokenOwner(), address(this), "tokenOwner");
    }

    // TODO: need to generate merkle trees/roots and test the claim function
}
