// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Liquidity} from "../src/Liquidity.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    Liquidity public liquidity;
    // address subToken;

    function setUp() public {
        liquidity = Liquidity(payable(0x282a3B11509C96e29Fbeb8B7968729ca2578AB9f));
        // subToken = address(0x9c38c668028Ab460341D9a76Dc31599a485C69F3);
    }

    function run() public {

        vm.startBroadcast();
        
        Liquidity liquidityImpl = new Liquidity();

        bytes memory data= "";
        Liquidity(payable(liquidity)).upgradeToAndCall(address(liquidityImpl), data);
        console.log("Before update rate:",liquidity.rate());
        liquidity.setRate(2000e18);
        console.log("After update rate:",liquidity.rate());
        vm.stopBroadcast();

        console.log("liquiqidty logic deployed to:", address(liquidityImpl));
        
    }
}
