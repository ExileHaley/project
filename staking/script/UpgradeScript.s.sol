// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingV3} from "../src/StakingV3.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    StakingV3 public stakingV3;

    function setUp() public {
        stakingV3 = StakingV3(payable(0x29F152B6881E5f3769972CeedDBC7Ca941947980));
    }

    function run() public {
        vm.startBroadcast();
        StakingV3 stakingImplV3 = new StakingV3();
        bytes memory data= "";
        StakingV3(payable(stakingV3)).upgradeToAndCall(address(stakingImplV3), data);
        vm.stopBroadcast();
    }
}
