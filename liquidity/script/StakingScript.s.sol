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
// snake地址:0xf7d6243b937136d432adbc643f311b5a9436b0b0
// 首码地址:0x2F76d6DE5FD5Bfb1b51e36eEBCb85cb8AaC680eE
// 白名单没有手续费的地址:0xA5a28c00f8caCe967C2737ddFb1101Ee951B7d36
// 子币地址:0x9c1bd25a5064ca1470704d672c0725314e1a8f9c

        token = address(0xF7d6243b937136d432AdBc643f311b5A9436b0B0);
        prefixCode = address(0x2F76d6DE5FD5Bfb1b51e36eEBCb85cb8AaC680eE);
        recipient = address(0xA5a28c00f8caCe967C2737ddFb1101Ee951B7d36);
        subToken = address(0x9C1BD25A5064ca1470704D672C0725314e1a8f9c);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
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
// stakingImpl deployed to: 0xB4406AB0353CC0C64363e723969F233378F4B497
//   Staking deployed to: 0xEdE92810065be4A55cbF0daca3a95e95D0f999E7