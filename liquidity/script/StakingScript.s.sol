// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingScriptMainnet is Script {
    Staking public staking;

    address token;
    address prefixCode;
    address recipient;
    address subToken;
    address usdt;
    uint256 rate;
    uint256 fee;
    uint256 swapRate;

    function setUp() public {
        token = address(0x1CCd53F4a12AE55BB8e2A19Fa37A7b1cfD4e7F3c);
        prefixCode = address(0x975382725cF0F99bA69615e3fE9d1f0D8DBdF1D6);
        recipient = address(0x975382725cF0F99bA69615e3fE9d1f0D8DBdF1D6);
        subToken = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        usdt = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    }

    function run() public {

        vm.startBroadcast();
        
        Staking stakingImpl = new Staking();

        ERC1967Proxy proxy = new ERC1967Proxy(address(stakingImpl), abi.encodeCall(
            stakingImpl.initialize, 
            (token, prefixCode, recipient, subToken, usdt, uint256(1000e18)/86400, fee, 400)
        ));

        staking = Staking(payable(proxy));


        vm.stopBroadcast();
        console.log("stakingImpl deployed to:", address(stakingImpl));
        console.log("Staking deployed to:", address(staking));
    }
}
