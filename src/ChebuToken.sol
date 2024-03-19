// SPDX-License-Identifier: MIT


pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TradeManager.sol";

contract ChebuToken is ERC20, TradeManager {

    uint256 immutable public MAX_TOTAL_SUPPLY =1_000_000_000_000e18;
   
    //address immutable public minter; // sale contract

    constructor (
        string memory _name, 
        string memory _symbol,
        address _feeBeneficiary,
        address _tradeFor
    )
        ERC20(_name, _symbol)
        TradeManager(_feeBeneficiary, _tradeFor)
    { 
        


    }

    function _mintFor(address _user, uint256 _amount) internal override {
        require(totalSupply() + _amount <= MAX_TOTAL_SUPPLY, "MAX_TOTAL_SUPPLY LIMIT");
        _mint(_user, _amount);
    }

    function _burnFor(address _user, uint256 _amount) internal override {
        _burn(_user, _amount);
    }

    function _distributedAmount() internal view override returns(uint256) {
        return totalSupply();
    }

    function _distributionTokenDecimals() internal view override returns(uint8) {
        return decimals();
    }
    
}

