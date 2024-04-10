// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";
import {TradeManager}  from "../src/TradeManager.sol";

contract ChebuTokenTest_a_03 is Test {

    struct Fee {
        uint256 total;
        uint256 claimed;
    }

    uint256 public outMEMCoinAmount = 2_000_001e18;
    //string public detrustName = 'NameOfDeTrust';
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
    function test_Mint_2000001() public {
        
        (uint256 inUSDTAmount, ) = memcoin.calcMintStableForExactTokens(outMEMCoinAmount);
        usdt.transfer(address(1), inUSDTAmount);
        vm.startPrank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);
        memcoin.mintTokensForExactStable(inUSDTAmount);
        vm.stopPrank();

        assertEq(memcoin.getCurrentRound(), 3); // check round number
        assertApproxEqAbs(memcoin.balanceOf(address(1)), outMEMCoinAmount,4e17);
    } 

    function test_Mint_1999999() public {
        outMEMCoinAmount = 1_999_999e18;
        (uint256 inUSDTAmount, ) = memcoin.calcMintStableForExactTokens(outMEMCoinAmount);
        usdt.transfer(address(1), inUSDTAmount);
        vm.startPrank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);
        memcoin.mintTokensForExactStable(inUSDTAmount);
        vm.stopPrank();

        assertEq(memcoin.getCurrentRound(), 2); // check round number
        assertApproxEqAbs(memcoin.balanceOf(address(1)), outMEMCoinAmount, 5e17);
    } 
}
