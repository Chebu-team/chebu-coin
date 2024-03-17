// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


import {MockERC20} from "../src/mock/MockERC20.sol";
import {UBDValidator}  from "../src/UBDValidator.sol";
import {Pausable}  from "../src/UBDValidator.sol";

contract ValidatorTest_m_01 is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    uint256 public sendUSDTAmount = 1e6;
    uint256 public sendUBDAmount = 2e18;
    //string public detrustName = 'NameOfDeTrust';
    UBDValidator  public validator;
    MockERC20 public usdt;
    MockERC20 public ubd;
    uint256 signerPrivateKey = 0xabc123;
    address public signerAddress = vm.addr(signerPrivateKey);
    
    

    receive() external payable virtual {}
    function setUp() public {
        usdt = new MockERC20('USDT test token', 'USDT');
        ubd = new MockERC20('UBD test token', 'UBD');
        validator = new UBDValidator(signerAddress, address(usdt), address(ubd));
        usdt.transfer(address(validator), sendUSDTAmount);
        ubd.transfer(address(validator), sendUBDAmount);
    }

    function test_RewardBalance() public view {
        uint256 usdtBalanceAfter = usdt.balanceOf(address(validator));
        uint256 ubdBalanceAfter = ubd.balanceOf(address(validator));
        assertEq(usdtBalanceAfter, sendUSDTAmount);
        //assertFalse(ubdBalanceAfter != sendUBDAmount);
        assertEq(ubdBalanceAfter, sendUBDAmount);
    }

    function test_Claim() public {
        

        uint256 usdtAmount = sendUSDTAmount / 10; 
        uint256 ubdAmount = sendUBDAmount / 10;
        
        bytes memory signature;

        uint256 claimerPrivateKey = 0xabc1234567890;
        address claimerAddress = vm.addr(claimerPrivateKey);
        uint32 nonce = validator.userNonce(claimerAddress) + 1;
        
        vm.startPrank(signerAddress);
        bytes32 digest = keccak256(abi.encodePacked(usdtAmount, ubdAmount , claimerAddress, nonce)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
        vm.stopPrank();

        vm.startPrank(signerAddress);
        vm.expectRevert(UBDValidator.BadSignature.selector);
        validator.claimReward(usdtAmount, ubdAmount, nonce, signature);
        vm.stopPrank();

        vm.startPrank(claimerAddress);
        validator.claimReward(usdtAmount, ubdAmount, nonce, signature);
        vm.stopPrank();

        vm.startPrank(claimerAddress);
        vm.expectRevert(
          abi.encodeWithSelector(UBDValidator.BadNonce.selector, 1)
        );
        validator.claimReward(usdtAmount, ubdAmount, nonce, signature);
        vm.stopPrank();

        //vm.startPrank(claimerAddress);
        // vm.expectRevert(
        //   abi.encodeWithSelector(UBDValidator.BadNonce.selector, 1)
        // );
        //validator.claimReward(usdtAmount, ubdAmount, nonce + 1, signature);
        //vm.stopPrank();


    }

    function test_checkSignature() public {
        

        uint256 usdtAmount = sendUSDTAmount / 10; 
        uint256 ubdAmount = sendUBDAmount / 10;
        
        bytes memory signature;

        uint256 claimerPrivateKey = 0xabc1234567890;
        address claimerAddress = vm.addr(claimerPrivateKey);
        uint32 nonce = validator.userNonce(claimerAddress) + 1;
        
        vm.startPrank(signerAddress);
        bytes32 digest = keccak256(abi.encodePacked(usdtAmount, ubdAmount , claimerAddress, nonce)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
        vm.stopPrank();

        assertEq(
           validator.checkSignature(usdtAmount, ubdAmount, nonce, claimerAddress),
           false
        );

        vm.startPrank(claimerAddress);
        validator.claimReward(usdtAmount, ubdAmount, nonce, signature);
        vm.stopPrank();

        assertEq(
           validator.checkSignature(usdtAmount, ubdAmount, nonce, claimerAddress),
           true
        );

    }

    function test_checkPause() public {
        

        uint256 usdtAmount = sendUSDTAmount / 10; 
        uint256 ubdAmount = sendUBDAmount / 10;
        
        bytes memory signature;

        uint256 claimerPrivateKey = 0xabc1234567890;
        address claimerAddress = vm.addr(claimerPrivateKey);
        uint32 nonce = validator.userNonce(claimerAddress) + 1;
        
        vm.startPrank(signerAddress);
        bytes32 digest = keccak256(abi.encodePacked(usdtAmount, ubdAmount , claimerAddress, nonce)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        signature = abi.encodePacked(r, s, v); // note the order here is different from line above.
        vm.stopPrank();

        validator.pause();

        vm.startPrank(claimerAddress);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        validator.claimReward(usdtAmount, ubdAmount, nonce, signature);
        vm.stopPrank();

        validator.unpause();

        vm.startPrank(claimerAddress);
        validator.claimReward(usdtAmount, ubdAmount, nonce, signature);
        vm.stopPrank();


        

    }

    
}
