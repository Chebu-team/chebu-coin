// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";
import {UBDValidator}  from "../src/UBDValidator.sol";


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

         // Define constructor params
        address ubd_address;   
        key = string.concat(".", vm.toString(block.chainid),".ubd_address");
        if (vm.keyExists(params_json_file, key)) 
        {
            ubd_address = params_json_file.readAddress(key);
        } else {
            ubd_address = address(0);
        }
        console2.log("ubd_address: %s", ubd_address); 

         // Define constructor params
        address signer_address;   
        key = string.concat(".", vm.toString(block.chainid),".signer_address");
        if (vm.keyExists(params_json_file, key)) 
        {
            signer_address = params_json_file.readAddress(key);
        } else {
            signer_address = msg.sender;
        }
        console2.log("signer_address: %s", signer_address); 

        //////////   Deploy   //////////////
        vm.startBroadcast();
        UBDValidator validator = new UBDValidator(signer_address, usdt_address, ubd_address);
        vm.stopBroadcast();
        
        ///////// Pretty printing ////////////////
        
        string memory path = string.concat(root, "/script/explorers.json");
        string memory json = vm.readFile(path);
        console2.log("Chain id: %s", vm.toString(block.chainid));
        string memory explorer_url = json.readString(
            string.concat(".", vm.toString(block.chainid))
        );
        
        console2.log("\n**UBDValidator**  ");
        console2.log("https://%s/address/%s#code\n", explorer_url, address(validator));

        console2.log("```python");
        console2.log("validator = UBDValidator.at('%s')", address(validator));
        console2.log("```");
   
        // ///////// End of pretty printing ////////////////

        // ///  Init ///
        console2.log("Init transactions....");
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
        console2.log("Initialisation finished");

    }
}
