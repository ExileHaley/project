// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingV2} from "../src/StakingV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    StakingV2 public stakingV2;

    function setUp() public {
        stakingV2 = StakingV2(payable(0x29F152B6881E5f3769972CeedDBC7Ca941947980));
    }

    function run() public {
        vm.startBroadcast();
        StakingV2 stakingImplV2 = new StakingV2();
        bytes memory data= "";
        StakingV2(payable(stakingV2)).upgradeToAndCall(address(stakingImplV2), data);
        vm.stopBroadcast();
    }
}
