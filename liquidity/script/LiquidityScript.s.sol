// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Liquidity} from "../src/Liquidity.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LiquidityScript is Script {
    Liquidity public liquidity;

    address token;
    address subToken;
    address prefixCode;
    // 代币合0xf7d6243b937136d432adbc643f311b5a9436b0b0
    //子币合0x9c1bd25a5064ca1470704d672c0725314e1a8f9c
    //首码0x2F76d6DE5FD5Bfb1b51e36eEBCb85cb8AaC680eE
    function setUp() public {
        token = address(0xF7d6243b937136d432AdBc643f311b5A9436b0B0);
        subToken = address(0x9C1BD25A5064ca1470704D672C0725314e1a8f9c);
        prefixCode = address(0x2F76d6DE5FD5Bfb1b51e36eEBCb85cb8AaC680eE);
    }

    function run() public {
        vm.startBroadcast();

        Liquidity liquidityImpl = new Liquidity();

        ERC1967Proxy proxy = new ERC1967Proxy(address(liquidityImpl), abi.encodeCall(
            liquidityImpl.initialize, 
            (token, subToken, prefixCode)
        ));
        liquidity = Liquidity(payable(proxy));

        vm.stopBroadcast();
        console.log("Liquidity deployed to:", address(liquidity));
    }
}

