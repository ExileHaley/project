// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingScriptMainnet is Script {
    Staking public staking;
    address public prefixCode;
    address public wukong;
    address public WETH;
    address public uniswapV2Factory;
    address public recipient;

    function setUp() public {
        prefixCode = address(0x975382725cF0F99bA69615e3fE9d1f0D8DBdF1D6);
        wukong = address(0x1CCd53F4a12AE55BB8e2A19Fa37A7b1cfD4e7F3c);
        WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        recipient = address(0x975382725cF0F99bA69615e3fE9d1f0D8DBdF1D6);
    }

    function run() public {
        vm.startBroadcast();
        
        Staking implementation = new Staking();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(
            implementation.initialize, 
            (wukong, prefixCode, uniswapV2Factory, recipient, WETH, uint256(2555e15) / 86400, 100)
        ));
        staking = Staking(payable(proxy));
    
        vm.stopBroadcast();

        console.log("Staking deployed to:", address(staking));
    }
}
