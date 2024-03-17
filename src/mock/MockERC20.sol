// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 dec;
	constructor(string memory name_, string memory symbol_, uint8 _decimals) 
	    ERC20(name_, symbol_)
	{
        dec = _decimals;
        _mint(msg.sender, 1_000_000_000e18); 
	}

	function decimals() public view override returns(uint8){
		return dec;
	}
}