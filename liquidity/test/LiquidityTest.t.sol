// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Liquidity} from "../src/Liquidity.sol";
import {FatTokenV5} from "../src/test/FatTokenV5.sol";
import {IERC20} from "../src/interface/IERC20.sol";
import {UniswapV2Library} from "../src/library/UniswapV2Library.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LiquidityTest is Test {
    Liquidity public liquidity;

    address owner;
    address token;
    address usdt;
    address subToken;
    address prefixCode;
    address user;
    address lpToken;
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        token = address(0xF7d6243b937136d432AdBc643f311b5A9436b0B0);
        subToken = address(0x1afFE3A7D63ffF6bE26c6F1ce91E76a04fb09917);
        prefixCode = address(0x174484Ed81c1AEdaE6789C3bAFA149d327C20435);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        lpToken = address(0x58604D87D22E9d265AEaa2352d994Fb6F626d636);
        owner = vm.addr(1);
        user = vm.addr(2);

        Liquidity liquidityImpl = new Liquidity();
        ERC1967Proxy proxy = new ERC1967Proxy(address(liquidityImpl), abi.encodeCall(
            liquidityImpl.initialize, 
            (token, subToken, prefixCode)
        ));
        liquidity = Liquidity(payable(proxy));
    }

    function testCanSwitchForks() public view{
        assertEq(vm.activeFork(), mainnetFork);
    }

    function testCanSetForkBlockNumber() public {
        // vm.selectFork(mainnetFork);
        vm.rollFork(41927121);
        assertEq(block.number, 41927121);
        console.log("Current Block Number:", block.number); 
    }


    function test_quote() public view {
        uint256 amountUSDTIn = liquidity.getQuoteAmount(1e18);
        console.log("amountUSDTIn result:", amountUSDTIn);

    }

    function test_invite() public {
        vm.startPrank(user);
        liquidity.invite(prefixCode);
        (address inviter,,,,,,,) = liquidity.getUserInfo(user);
        assertEq(inviter, prefixCode);
        vm.stopPrank();
    }

    function test_provide() public {
        vm.startPrank(user);
        liquidity.invite(prefixCode);
        deal(token, address(user), 10e18);
        deal(usdt, address(user), 30000e18);
        IERC20(token).approve(address(liquidity), 100000000e18);
        IERC20(usdt).approve(address(liquidity), 100000000e18);
        liquidity.provide(1e18);
        vm.stopPrank();

        (,,,uint256 value,,,,) = liquidity.getUserInfo(user);
        console.log("User staking Value:", value);
        console.log("Liquidity amount of liquidity:", IERC20(lpToken).balanceOf(address(liquidity)));
    }

    function test_income() public {
        vm.startPrank(user);
        liquidity.invite(prefixCode);
        deal(token, address(user), 10e18);
        deal(usdt, address(user), 30000e18);
        IERC20(token).approve(address(liquidity), 100000000e18);
        IERC20(usdt).approve(address(liquidity), 100000000e18);
        liquidity.provide(1e18);
        console.log("Liquidity amount of liquidity:", IERC20(lpToken).balanceOf(address(liquidity)));
        vm.warp(block.timestamp + 60 days);
        console.log("Income of one day:", liquidity.getUserIncome(user));
        vm.startPrank(user);
    }


    function test_claim() public {
        vm.startPrank(user);
        liquidity.invite(prefixCode);
        deal(token, address(user), 10e18);
        deal(usdt, address(user), 30000e18);
        deal(subToken, address(liquidity), 1000e18);
        IERC20(token).approve(address(liquidity), 100000000e18);
        IERC20(usdt).approve(address(liquidity), 100000000e18);
        liquidity.provide(1e18);
        vm.warp(block.timestamp + 1 days);
        liquidity.claim();
        assertEq(liquidity.getUserIncome(user), 0);
        vm.startPrank(user);
    }

}
