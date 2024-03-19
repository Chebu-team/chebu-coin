// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";

contract ChebuTokenTest_m_01 is Test {

    uint256 public inAmountStable_1 = 2_100_000;
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
        //usdt.transfer(address(validator), sendUSDTAmount);
    }

    function test_TokenParams() public view {
        assertEq(usdt.balanceOf(address(this)), usdt.totalSupply());
        assertEq(memcoin.totalSupply(), 0);
        assertEq(memcoin.ROUND_VOLUME(), 1_000_000e18);

    }
    
    function test_MintPrice() public view {
        (uint256 price, ) = memcoin.priceAndRemainByRound(1);
        assertEq(price, 1);
        (uint256 outAmount, uint256 inAmountFee) = memcoin.calcMintTokensForExactStable(inAmountStable_1);
        assertEq(outAmount,15e23);
        assertEq(inAmountFee, 1e5);
        (uint256 inAmount, uint256 includeFee) = memcoin.calcMintStableForExactTokens(15e23); 
        assertEq(inAmount, inAmountStable_1);
        assertEq(includeFee, 1e5);
    }

    function test_Mint() public  {
        usdt.approve(address(memcoin), inAmountStable_1);
        memcoin.mintTokensForExactStable(inAmountStable_1);
        assertEq(memcoin.totalSupply(), 1_500_000e18);
        assertEq(memcoin.balanceOf(address(this)), 1_500_000e18);
        //assertEq(memcoin.fee().total, 1e5);
        assertEq(usdt.balanceOf(address(memcoin)), inAmountStable_1);
    }

    function test_BurnPrice() public  {
        usdt.approve(address(memcoin), inAmountStable_1);
        memcoin.mintTokensForExactStable(inAmountStable_1);
        (uint256 price, uint256 minted) = memcoin.priceAndMintedInRound(2);
        assertEq(price, 2);
        assertEq(minted, 500_000e18);
        (uint256 outAmount, uint256 outAmountFee) = memcoin.calcBurnExactTokensForStable(1_500_000e18);
        assertEq(outAmount, 1_900000);
        assertEq(outAmountFee, 100000);
        (uint256 inAmount, uint256 includeFee) = memcoin.calcBurnTokensForExactStable(1_900000);
        assertEq(inAmount, 1_500_000e18);
        assertEq(includeFee, 100000);
    }

    function test_Burn() public  {
        usdt.approve(address(memcoin), inAmountStable_1);
        memcoin.mintTokensForExactStable(inAmountStable_1);
        memcoin.approve(address(memcoin), memcoin.balanceOf(address(this)));
        memcoin.burnExactTokensForStable(memcoin.balanceOf(address(this)));
        (uint256 t, ) = memcoin.fee();
        assertEq(memcoin.totalSupply(), 0);
        assertEq(usdt.balanceOf(address(memcoin)), t);
    }
}
