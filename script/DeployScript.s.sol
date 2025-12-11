// SPDX-License-Identifier:MIT
pragma solidity 0.8.30;
import {Script} from "../lib/forge-std/src/Script.sol";
import {Roulette} from "../src/Roulette.sol";

contract DeployScript is Script {
    
    address deployer;

    function run() public returns (Roulette, address) {
        deployer = 0x7ec1E12fc360acd02Fd2a493AcA2085A468Bbc95;
        
        vm.startBroadcast(deployer);
        
        Roulette rObject = new Roulette(deployer);
        
        vm.stopBroadcast();

        return (rObject, deployer);
    }
}
