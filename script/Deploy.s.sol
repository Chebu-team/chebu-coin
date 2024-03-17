// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";
import {ChebuToken}  from "../src/ChebuToken.sol";


contract DeployScript is Script {
    using stdJson for string;

    function run() public {
        console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log("Deployer address: %s, native balnce %s", msg.sender, msg.sender.balance);

        // Load json with chain params
        string memory root = vm.projectRoot();
        string memory params_path = string.concat(root, "/script/chain_params.json");
        string memory params_json_file = vm.readFile(params_path);
        string memory key;

        // Define constructor params
        address usdt_address;   
        key = string.concat(".", vm.toString(block.chainid),".usdt_address");
        if (vm.keyExists(params_json_file, key)) 
        {
            usdt_address = params_json_file.readAddress(key);
        } else {
            usdt_address = address(0);
        }
        console2.log("usdt_address: %s", usdt_address); 
        
        string memory name_token;   
        key = string.concat(".", vm.toString(block.chainid),".name_token");
        if (vm.keyExists(params_json_file, key)) 
        {
            name_token = params_json_file.readString(key);
        } else {
            name_token = 'Chebu Mem Coin';
        }
        console2.log("name_token: %s", name_token); 

        string memory symb_token;   
        key = string.concat(".", vm.toString(block.chainid),".symb_token");
        if (vm.keyExists(params_json_file, key)) 
        {
            symb_token = params_json_file.readString(key);
        } else {
            symb_token = 'CHEBU';
        }
        console2.log("symb_token: %s", symb_token);
        
        address fee_beneficiary;   
        key = string.concat(".", vm.toString(block.chainid),".fee_beneficiary");
        if (vm.keyExists(params_json_file, key)) 
        {
            fee_beneficiary = params_json_file.readAddress(key);
        } else {
            fee_beneficiary = address(0);
        }
        console2.log("fee_beneficiary: %s", fee_beneficiary); 

        address trade_for;   
        key = string.concat(".", vm.toString(block.chainid),".fee_beneficiary");
        if (vm.keyExists(params_json_file, key)) 
        {
            trade_for = params_json_file.readAddress(key);
        } else {
            trade_for = address(0);
        }
        console2.log("trade_for: %s", trade_for); 

        //////////   Deploy   //////////////
        vm.startBroadcast();
        ChebuToken memcoin = new ChebuToken(
            name_token, 
            symb_token, 
            fee_beneficiary,
            trade_for,
            6

        );
        vm.stopBroadcast();
        
        ///////// Pretty printing ////////////////
        
        string memory path = string.concat(root, "/script/explorers.json");
        string memory json = vm.readFile(path);
        console2.log("Chain id: %s", vm.toString(block.chainid));
        string memory explorer_url = json.readString(
            string.concat(".", vm.toString(block.chainid))
        );
        
        console2.log("\n**ChebuToken**  ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(memcoin));

        console2.log("```python");
        console2.log("memcoin = ChebuToken.at('%s')", address(memcoin));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////

        // ///  Init ///
        // console2.log("Init transactions....");
        // vm.startBroadcast();
        // modelReg.setModelState(
        //     address(impl_00),
        //     DeTrustModelRegistry.TrustModel(0x03, ubdn_address, neededERC20Amount, address(0))
        // );
        // userReg.setFactoryState(address(factory), true);

        // // test transactions
        // if (inheriter != address(0)){
        //     address proxy = factory.deployProxyForTrust(
        //         address(impl_00), 
        //         msg.sender,
        //         keccak256(abi.encode(address(2))), 
        //         uint64(silentPeriod),
        //         'InitialTrust'
        //     );
        //     console2.log("detrust deployed at('%s')", address(proxy));
        //     console2.log("https://%s/address/%s#code\n", explorer_url, address(proxy));

        // }
        
        // vm.stopBroadcast();
        // console2.log("Initialisation finished");

    }
}
