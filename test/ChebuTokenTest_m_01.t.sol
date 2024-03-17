// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";

contract ChebuTokenTest_m_01 is Test {

    uint256 public sendUSDTAmount = 1e6;
    uint256 public sendUBDAmount = 2e18;
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
            address(usdt),
            usdt.decimals()
        );
        //usdt.transfer(address(validator), sendUSDTAmount);
    }

    // function test_TokenParams() public view {
    //     uint256 usdtBalanceAfter = usdt.balanceOf(address(validator));
    //     uint256 ubdBalanceAfter = ubd.balanceOf(address(validator));
    //     assertEq(usdtBalanceAfter, sendUSDTAmount);
    //     //assertFalse(ubdBalanceAfter != sendUBDAmount);
    //     assertEq(ubdBalanceAfter, sendUBDAmount);
    // }

    

}
