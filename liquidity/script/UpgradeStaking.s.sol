// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeStaking is Script {
    Staking public staking;
    // address subToken;

    function setUp() public {
        staking = Staking(payable(0xEdE92810065be4A55cbF0daca3a95e95D0f999E7));
        // subToken = address(0x9c38c668028Ab460341D9a76Dc31599a485C69F3);
    }

    function run() public {

        vm.startBroadcast();
        console.log("Before withdraw fee:", staking.fee());
        console.log("Before reward rate:", staking.rate());
        console.log("Before swap rate:", staking.swapRate());
        staking.setConfig(uint256(1000e18)/86400, 75);

        console.log("After withdraw fee:", staking.fee());
        console.log("After reward rate:", staking.rate());
        console.log("After swap rate:", staking.swapRate());

        vm.stopBroadcast();

        
    }
}
//forge script script/UpgradeStaking.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
