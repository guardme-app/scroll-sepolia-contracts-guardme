// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { GuardMe } from "src/GuardMe.sol";

contract Deployer is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        deploy();
        vm.stopBroadcast();
    }

    function deploy() public returns (GuardMe) {
        GuardMe guardMe = new GuardMe();

        console.log('GuardMe deployed at address: ', address(guardMe));

        return guardMe;
    }
}
