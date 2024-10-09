// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingV3} from "../src/StakingV3.sol";
import {Wukong} from "../src/Wukong.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingScriptMainnet is Script {
    StakingV3 public stakingV3;
    Wukong public wukong;
    uint256 exchangeRate = 3000e18;
    uint256 purchaseRate = 1e17;
    address BNBRecipient;
    address nftSubToken;


    function setUp() public {
        stakingV3 = StakingV3(payable(0x29F152B6881E5f3769972CeedDBC7Ca941947980));
        BNBRecipient = address(0xae5A2FEf06951Dbd0D5E776a5E74c2bADdcE8F51);
        //更新
        nftSubToken = address(0x1CCd53F4a12AE55BB8e2A19Fa37A7b1cfD4e7F3c);
    }

    function run() public {

        vm.startBroadcast();

        wukong = new Wukong();
        wukong.setUrl("https://test.com/");

        StakingV3 stakingImplV3 = new StakingV3();
        bytes memory data= "";
        StakingV3(payable(stakingV3)).upgradeToAndCall(address(stakingImplV3), data);
        stakingV3.setNftConfig(address(wukong), exchangeRate, purchaseRate, BNBRecipient, nftSubToken);

        wukong.transferOwnership(address(payable(stakingV3)));
        vm.stopBroadcast();
        console.log("Wukong deployed to:", address(wukong));
    }
}
