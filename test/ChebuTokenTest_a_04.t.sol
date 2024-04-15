// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";
import {TradeManager}  from "../src/TradeManager.sol";

contract ChebuTokenTest_a_04 is Test {
    struct Fee {
        uint256 total;
        uint256 claimed;
    }

    ChebuToken  public memcoin;
    MockERC20 public usdt;
    

    receive() external payable virtual {}
    function setUp() public {
        usdt = new MockERC20('USDT test token', 'USDT', 6);
        memcoin = new ChebuToken(
            'Chebu Mem Coin', 
            'CHEBU', 
            address(this),
            address(usdt)
        );
    }

// use boundary conditions
    function test_FuzzTest(uint48 inUSDTAmount) public {
        vm.assume(inUSDTAmount > 1e2);
        console2.log(inUSDTAmount);

        (uint256 outMEMCoinAmount, ) = memcoin.calcMintTokensForExactStable(inUSDTAmount);
        usdt.transfer(address(1), inUSDTAmount);
        vm.startPrank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);
        memcoin.mintTokensForExactStable(inUSDTAmount);
        vm.stopPrank();

        //assertEq(memcoin.getCurrentRound(), 3); // check round number
        assertApproxEqAbs(memcoin.balanceOf(address(1)), outMEMCoinAmount,4e17);
        assertEq(usdt.balanceOf(address(memcoin)), inUSDTAmount);
    } 
}
