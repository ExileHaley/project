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

    function setUp() public {
        token = address(0xF7d6243b937136d432AdBc643f311b5A9436b0B0);
        subToken = address(0x55d398326f99059fF775485246999027B3197955);
        prefixCode = address(0x55d398326f99059fF775485246999027B3197955);
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

