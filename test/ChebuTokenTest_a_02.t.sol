// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";
import {TradeManager}  from "../src/TradeManager.sol";

contract ChebuTokenTest_a_02 is Test {

    struct Fee {
        uint256 total;
        uint256 claimed;
    }

    uint256 public inUSDTAmount = 1_000_000e6; // 1 000 000 usdt
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

// use huge amounts
    function test_Mint() public {
        
        usdt.transfer(address(1), inUSDTAmount);
        vm.prank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);

        uint256 inCleanedUSDTAmount = inUSDTAmount * 100 * memcoin.PERCENT_DENOMINATOR() / 
            (100 * memcoin.PERCENT_DENOMINATOR() + memcoin.FEE_PERCENT_POINT());
        uint256 calculatedFee = inUSDTAmount - inCleanedUSDTAmount;

        uint256 round = 1;
        uint256 price = 0;
        uint256 roundUSDTAmount = 0;
        uint256 memcoinAmount = 0;
        uint256 beforeUSDTContractBalance = usdt.balanceOf(address(memcoin));

        while (inCleanedUSDTAmount > 0) {
            price = memcoin.START_PRICE() + (round - 1) * memcoin.PRICE_INCREASE_STEP(); //per 1e12 memcoins
            roundUSDTAmount = memcoin.ROUND_VOLUME() * price / 
                (10 ** memcoin.decimals()); 
            if (inCleanedUSDTAmount > roundUSDTAmount) {
                memcoinAmount += memcoin.ROUND_VOLUME();
                inCleanedUSDTAmount -= roundUSDTAmount;
                round += 1;
            } else {
                memcoinAmount += inCleanedUSDTAmount * 10 ** memcoin.decimals() / price;
                inCleanedUSDTAmount = 0;
            }
        }
        (uint256 outAmount, uint256 inAmountFee) = memcoin.calcMintTokensForExactStable(inUSDTAmount);
        assertEq(outAmount,memcoinAmount);
        assertEq(inAmountFee, calculatedFee);

        vm.prank(address(1));
        memcoin.mintTokensForExactStable(inUSDTAmount);
        assertEq(round, memcoin.getCurrentRound());
        assertEq(memcoin.totalSupply(),memcoinAmount);

        (uint256 total, uint256 claimed) = memcoin.fee();
        assertEq(total, calculatedFee);
        assertEq(claimed, 0);

        assertEq(usdt.balanceOf(address(memcoin)), beforeUSDTContractBalance + inUSDTAmount);

        // try to calculate memcoin amount for exact usdt amount
        // next 1 000 000 usdt

        inCleanedUSDTAmount = inUSDTAmount * 100 * memcoin.PERCENT_DENOMINATOR() / 
            (100 * memcoin.PERCENT_DENOMINATOR() + memcoin.FEE_PERCENT_POINT());
        calculatedFee = inUSDTAmount - inCleanedUSDTAmount;
        uint256 lastUSDTForCurrentRound = (round * memcoin.ROUND_VOLUME() - 
            memcoinAmount) * price / 10 ** memcoin.decimals();

        // close current round and prepare data for next purchases
        inCleanedUSDTAmount = inCleanedUSDTAmount - lastUSDTForCurrentRound;
        uint256 memcoinAmountBefore = memcoinAmount;
        memcoinAmount = round * memcoin.ROUND_VOLUME();
        round += 1; 


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
            round += 1;
        }

        (outAmount, inAmountFee) = memcoin.calcMintTokensForExactStable(inUSDTAmount);
        assertEq(inAmountFee, calculatedFee);
        assertEq(outAmount, memcoinAmount - memcoinAmountBefore);

        (uint256 inAmount, ) = memcoin.calcMintStableForExactTokens(memcoinAmount - memcoinAmountBefore);
        assertApproxEqAbs(inUSDTAmount, inAmount, 3);

        // buy the next part of memcoins (by 1000 000 usdt)
        usdt.transfer(address(1), inUSDTAmount);
        vm.startPrank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);
        memcoin.mintTokensForExactStable(inUSDTAmount);
        vm.stopPrank();

        assertEq(memcoinAmount, memcoin.totalSupply());

        assertEq(memcoin.balanceOf(address(1)),memcoinAmount);
    }

    function test_Burn() public {
         // calculate burn
        inUSDTAmount = 2_000_000e6; // 2 000 000 usdt
        usdt.transfer(address(1), inUSDTAmount);
        vm.startPrank(address(1));
        usdt.approve(address(memcoin), inUSDTAmount);
        memcoin.mintTokensForExactStable(inUSDTAmount);
        vm.stopPrank();
        uint256 round = memcoin.getCurrentRound();
        uint256 memcoinAmount = memcoin.totalSupply();
        uint256 burntAmount = 200_000_000e18; // burnt amount
        uint256 restMemcoinsInLastRound =  memcoinAmount - (round - 1) * memcoin.ROUND_VOLUME();
        uint256 price = memcoin.START_PRICE() + (round - 1) * memcoin.PRICE_INCREASE_STEP();
        uint256 bAm = burntAmount - restMemcoinsInLastRound;
        uint256 calculatedUSDT = restMemcoinsInLastRound * price / 10 ** memcoin.decimals();
        memcoinAmount -= restMemcoinsInLastRound;

        round -= 1;
        uint256 beforeUSDTAccBalance = usdt.balanceOf(address(1));
        uint256 beforeUSDTContractBalance = usdt.balanceOf(address(memcoin));
        while (bAm > 0) {
            price = memcoin.START_PRICE() + (round - 1) * memcoin.PRICE_INCREASE_STEP(); //per 1e12 memcoins
            if (bAm > memcoin.ROUND_VOLUME()) {
                calculatedUSDT += memcoin.ROUND_VOLUME() * price / 
                (10 ** memcoin.decimals());
                memcoinAmount -= memcoin.ROUND_VOLUME();
                bAm -= memcoin.ROUND_VOLUME();
                round -= 1;     
            } else {
                calculatedUSDT += bAm * price / (10 ** memcoin.decimals());
                memcoinAmount -= bAm;
                bAm = 0;
            }
        }

        uint256 outUsdtAmount = calculatedUSDT * 
            (100 * memcoin.PERCENT_DENOMINATOR() - memcoin.FEE_PERCENT_POINT()) / 
            (100 * memcoin.PERCENT_DENOMINATOR());
        uint256 fee = calculatedUSDT - outUsdtAmount;
        (uint256 outAmount, uint256 outAmountFee) = memcoin.calcBurnExactTokensForStable(burntAmount);
        assertApproxEqAbs(outUsdtAmount, outAmount, 1);
        assertApproxEqAbs(outAmountFee, fee, 1);

        (uint256 inAmount, uint256 includeFee) = memcoin.calcBurnTokensForExactStable(outUsdtAmount);
        assertApproxEqAbs(includeFee, fee, 1);
        assertApproxEqAbs(inAmount, burntAmount, 10 ** (memcoin.decimals() - 1));

        vm.startPrank(address(1));
        memcoin.approve(address(memcoin), burntAmount);
        emit TradeManager.Deal(address(1), address(memcoin), burntAmount, outUsdtAmount);
        memcoin.burnExactTokensForStable(burntAmount);
        vm.stopPrank();
        assertEq(memcoin.balanceOf(address(1)), memcoin.totalSupply());
        assertEq(memcoin.balanceOf(address(1)), memcoinAmount);
        assertApproxEqAbs(usdt.balanceOf(address(1)), beforeUSDTAccBalance + outUsdtAmount, 1);
        assertApproxEqAbs(usdt.balanceOf(address(memcoin)), beforeUSDTContractBalance - outUsdtAmount, 1);
        assertEq(round, memcoin.getCurrentRound());
    } 
}
