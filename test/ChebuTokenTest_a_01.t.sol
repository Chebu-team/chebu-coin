// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";

contract ChebuTokenTest_a_01 is Test {

    struct Fee {
        uint256 total;
        uint256 claimed;
    }

    uint256 public inUSDTAmount = 1_000_000_000_000e6; //15 usdt
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


    function test_Mint() public {
        usdt.transfer(address(1), inUSDTAmount);
        vm.prank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);

        //buy memcoins - with revert
        vm.prank(address(1));
        vm.expectRevert("MAX_TOTAL_SUPPLY LIMIT");
        memcoin.mintTokensForExactStable(inUSDTAmount);

        inUSDTAmount = 15e6; //15 usdt

        uint256 inCleanedUSDTAmount = inUSDTAmount * 100 * memcoin.PERCENT_DENOMINATOR() / 
            (100 * memcoin.PERCENT_DENOMINATOR() + memcoin.FEE_PERCENT_POINT());
        uint256 calculatedFee = inUSDTAmount - inCleanedUSDTAmount;

        uint256 round = 1;
        uint256 price = 0;
        uint256 roundUSDTAmount = 0;
        uint256 memcoinAmount = 0;
        uint256 beforeBalance = usdt.balanceOf(address(memcoin));

        while (inCleanedUSDTAmount > 0) {
            price = memcoin.START_PRICE() + (round - 1) * memcoin.PRICE_INCREASE_STEP(); //per 1e12 memcoins
            roundUSDTAmount = memcoin.ROUND_VOLUME() * price / 
                (10 ** memcoin.decimals()); 
            if (inCleanedUSDTAmount > roundUSDTAmount) {
                memcoinAmount += memcoin.ROUND_VOLUME();
                inCleanedUSDTAmount -= roundUSDTAmount;
            } else {
                memcoinAmount += inCleanedUSDTAmount * 10 ** memcoin.decimals() / price;
                inCleanedUSDTAmount = 0;
            }
            console2.log('round = ', round);
            console2.log('price = ', price);
            console2.log('roundUSDTAmount = ', roundUSDTAmount);
            console2.log('memcoinAmount = ', memcoinAmount);
            console2.log('inCleanedUSDTAmount = ', inCleanedUSDTAmount);
            console2.log('next round');
            
            round += 1;
        //    if (round == 2 ) {break;}
        }
        (uint256 outAmount, uint256 inAmountFee) = memcoin.calcMintTokensForExactStable(inUSDTAmount);
        console2.log(inAmountFee);
        assertEq(outAmount,memcoinAmount);
        assertEq(inAmountFee, calculatedFee);

        vm.prank(address(1));
        memcoin.mintTokensForExactStable(inUSDTAmount);
        assertEq(round - 1, memcoin.getCurrentRound());
        assertEq(memcoin.totalSupply(),memcoinAmount);

        (uint256 total, uint256 claimed) = memcoin.fee();
        assertEq(total, calculatedFee);
        assertEq(claimed, 0);

        assertEq(usdt.balanceOf(address(memcoin)), beforeBalance + inUSDTAmount);

        vm.prank(address(1));
        vm.expectRevert("Unauthorized");
        memcoin.claimFee(calculatedFee);

        vm.prank(address(this));
        vm.expectRevert();
        memcoin.claimFee(calculatedFee + 1);

        beforeBalance = usdt.balanceOf(address(memcoin));
        uint256 beforeThisBalance = usdt.balanceOf(address(this));
        vm.prank(address(this));
        memcoin.claimFee(calculatedFee / 10);
        (total, claimed) = memcoin.fee();
        assertEq(claimed, calculatedFee / 10);
        assertEq(total, calculatedFee);

        assertEq(usdt.balanceOf(address(memcoin)), beforeBalance - calculatedFee / 10);
        assertEq(usdt.balanceOf(address(this)), beforeThisBalance + calculatedFee / 10);     
    
    }
}
