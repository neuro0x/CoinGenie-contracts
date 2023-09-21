// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// solhint-disable-next-line no-global-import
import "../lib/forge-std/src/Test.sol";

import { SafeMath } from "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import { AirdropERC20 } from "../src/AirdropERC20.sol";

import { MockERC20 } from "./mocks/ERC20.mock.sol";

contract AirdropERC20Test is Test {
    using SafeMath for uint256;

    uint256 public constant MAX_TOKEN_SUPPLY = 100_000_000_000 ether;

    mapping(address user => uint256 balance) public balances;

    AirdropERC20 public airdropContract;
    MockERC20 public mockERC20;

    uint256 public minEthFee;

    function setUp() public {
        airdropContract = new AirdropERC20();
        mockERC20 = new MockERC20("Mock", "MOCK", 18);
        mockERC20.mint(address(this), MAX_TOKEN_SUPPLY);
    }

    function testFuzz_Airdrop(address[] memory recipients) public {
        vm.assume(recipients.length > 0);
        vm.assume(recipients.length < 50);

        uint256 totalAmount = 0;
        uint256[] memory amounts = new uint256[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount = totalAmount.add(MAX_TOKEN_SUPPLY.div(recipients.length));
            amounts[i] = MAX_TOKEN_SUPPLY.div(recipients.length);
            balances[recipients[i]] = balances[recipients[i]].add(amounts[i]);
        }

        AirdropERC20.AirdropContent[] memory contents = new AirdropERC20.AirdropContent[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            contents[i] = AirdropERC20.AirdropContent({ recipient: recipients[i], amount: amounts[i] });
        }

        mockERC20.approve(address(airdropContract), totalAmount);
        airdropContract.airdrop{ value: minEthFee }(address(mockERC20), address(this), contents);

        for (uint256 i = 0; i < contents.length; i++) {
            assertLe(mockERC20.balanceOf(contents[i].recipient), balances[contents[i].recipient], "balanceOf");
        }
    }
}
