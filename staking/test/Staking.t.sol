// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StakingV3} from "../src/StakingV3.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Wukong} from "../src/Wukong.sol";

contract StakingTest is Test {
    StakingV3 public stakingV3;
    Wukong public wukong;
    address public nftRecipient;
    address public owner;
    address public prefixCode;
    address public subToken;

    uint256 mainnetFork;

    function setUp() public{
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        owner = address(0x1e6470e6538E2A1BB02655Cd62195c6FbebdEBb4);
        nftRecipient = address(0xae5A2FEf06951Dbd0D5E776a5E74c2bADdcE8F51);
        stakingV3 = StakingV3(payable(0x29F152B6881E5f3769972CeedDBC7Ca941947980));
        prefixCode = address(0x975382725cF0F99bA69615e3fE9d1f0D8DBdF1D6);
        subToken = address(0x9c38c668028Ab460341D9a76Dc31599a485C69F3);
        vm.startPrank(owner);
        StakingV3 stakingImplV3 = new StakingV3();
        bytes memory data= "";
        StakingV3(payable(stakingV3)).upgradeToAndCall(address(stakingImplV3), data);

        wukong = new Wukong();
        wukong.setUrl("https://test.com/");
        wukong.transferOwnership(address(payable(stakingV3)));
        stakingV3.setNftConfig(address(wukong), 3000e18, 1e17, nftRecipient, subToken);
        vm.stopPrank();
    }

    
    function test_purchase() public {
        address user = vm.addr(1);
        deal(user, 11 * 1e17);
        vm.startPrank(user);
        stakingV3.invite(prefixCode);
        stakingV3.purchase{value:11 * 1e17}(11);
        assertEq(wukong.balanceOf(user), 11);
        assertEq(wukong.balanceOf(prefixCode), 1);
        assertEq(stakingV3.getInvitePurchaseAmount(prefixCode), 1);
        assertEq(wukong.index(), 13);
        assertEq(nftRecipient.balance, 11 * 1e17);
        vm.stopPrank;
    }

    function test_swap() public {
        address user1 = vm.addr(2);
        deal(user1, 10 * 1e17);
        vm.startPrank(user1);
        stakingV3.invite(prefixCode);
        stakingV3.purchase{value:10 * 1e17}(10);
        uint256[] memory tokenIds = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            tokenIds[i] = i + 1; // 赋值 1 到 10
        }

        wukong.setApprovalForAll(address(stakingV3), true);

        stakingV3.swap(tokenIds);
        assertEq(wukong.balanceOf(user1), 0);
        assertEq(wukong.balanceOf(address(stakingV3)), 10);

        assertEq(wukong.balanceOf(prefixCode), 1);

        assertEq(IERC20(subToken).balanceOf(user1), 10 * 3000e18);
        assertEq(nftRecipient.balance, 10 * 1e17);
        
        vm.stopPrank;
    }

    function test_url() public {
        vm.startPrank(owner);
        stakingV3.setNftOwner(owner);
        wukong.mint(1);
        console.log("1",wukong.tokenURI(1));
        wukong.mint(999);
        console.log("999",wukong.tokenURI(999));
        wukong.mint(1000);
        console.log("1000",wukong.tokenURI(1000));

        wukong.mint(1001);
        console.log("1001",wukong.tokenURI(1001));

        wukong.mint(1999);
        console.log("1999",wukong.tokenURI(1999));

        wukong.mint(2000);
        console.log("2000",wukong.tokenURI(2000));

        wukong.mint(2001);
        console.log("2001",wukong.tokenURI(2001));

        wukong.mint(2999);
        console.log("2999",wukong.tokenURI(2999));

        wukong.mint(9999);
        console.log("9999",wukong.tokenURI(9999));

        wukong.mint(10000);
        console.log("10000",wukong.tokenURI(10000));
        vm.stopPrank();
    }

}

// contract StakingTest is Test {
//     Staking public staking;
//     address wukong;
//     address WETH;
//     address uniswapV2Factory;
    
//     address prefixCode;
//     address recipient;
//     address user;
//     address userDown;
//     uint256 mainnetFork;

//     function setUp() public {
//         mainnetFork = vm.createFork(vm.envString("rpc_url"));
//         vm.selectFork(mainnetFork);

//         prefixCode = vm.addr(2);
//         user = vm.addr(4);
//         userDown = vm.addr(5);
//         wukong = address(0x1CCd53F4a12AE55BB8e2A19Fa37A7b1cfD4e7F3c);
//         WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
//         uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
//         recipient = address(0x975382725cF0F99bA69615e3fE9d1f0D8DBdF1D6);

//         Staking implementation = new Staking();
//         ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(
//             implementation.initialize, 
//             (wukong, prefixCode, uniswapV2Factory, recipient, WETH, uint256(2555e15) / 86400, 100)
//         ));
//         staking = Staking(payable(proxy));
//     }

//     function testCanSwitchForks() public view{
//         assertEq(vm.activeFork(), mainnetFork);
//     }

//     function testCanSetForkBlockNumber() public {
//         // vm.selectFork(mainnetFork);
//         vm.rollFork(41927121);
//         assertEq(block.number, 41927121);
//         console.log("Current Block Number:", block.number); 
//     }


//     function test_config() public view {
//         assertEq(staking.token(), wukong);
//         assertEq(staking.WETH(), WETH);
//         assertEq(staking.uniswapV2Factory(), uniswapV2Factory);
//     }

//     function test_getAmountOut() public view {
//         uint256 amountOut = staking.getAmountOut(WETH, wukong, 1e18);
//         console.log("AmountOut result:", amountOut);
//     }

//     function test_invite() public {
//         vm.startPrank(user);
//         staking.invite(prefixCode);
//         (address _inviter,,,,,) = staking.getUserInfo(user);
//         (,,,,address[] memory _members,) = staking.getUserInfo(prefixCode);
//         assertEq(_inviter, prefixCode);
//         assertEq(_members[0], user);
//         vm.stopPrank();
//     }

//     function test_provide() public {
//         test_invite();
//         vm.startPrank(user);
//         deal(wukong, user, 1e18);
//         IERC20(wukong).approve(address(staking),1e18);
//         staking.provide(1e17);
//         // address _inviter,
//         // uint256 _staking,
//         // uint256 _dynamic,
//         // uint256 _income,
//         // address[] memory _members,
//         // Record[]  memory _records
//         (,uint256 _staking,uint256 _dynamic,uint256 _income,,) = staking.getUserInfo(user);
//         assertEq(_staking, 1e17);
//         assertEq(_dynamic, 0);
//         console.log("getUserIncome:", _income);
//         (,,_dynamic,,,)= staking.getUserInfo(prefixCode);
//         assertEq(_dynamic, 1e16);
//         vm.stopPrank();
//     }

//     function test_withdraw() public {
//         test_provide();
//         vm.startPrank(recipient);
//         IERC20(wukong).approve(address(staking), 10000e18);
//         vm.stopPrank();
//         (,uint256 _staking,,,,) = staking.getUserInfo(user);
//         assertEq(_staking, 1e17);
//         vm.startPrank(user);
//         staking.withdraw();
//         (,_staking,,,,) = staking.getUserInfo(user);
//         assertEq(_staking, 0);
//         (,,uint256 _dynamic,,,) = staking.getUserInfo(prefixCode);
//         assertEq(_dynamic, 0);
//         vm.stopPrank();
//     }

//     function test_Hierarchy() public {
//         vm.startPrank(user);
//         staking.invite(prefixCode);
//         deal(wukong, user, 1e18);
//         IERC20(wukong).approve(address(staking),1e18);
//         staking.provide(1e18);
//         vm.stopPrank();

//         vm.startPrank(userDown);
//         staking.invite(user);
//         deal(wukong, userDown, 1e18);
//         IERC20(wukong).approve(address(staking),1e18);
//         staking.provide(1e18);
//         (,,uint256 _dynamic,,,) = staking.getUserInfo(user);
//         assertEq(_dynamic, 1e17);
//         (,,_dynamic,,,) = staking.getUserInfo(prefixCode);
//         assertEq(_dynamic, 15e16);
//         vm.stopPrank();


//         vm.startPrank(recipient);
//         IERC20(wukong).approve(address(staking), 10000e18);
//         vm.stopPrank();

//         vm.startPrank(userDown);
//         staking.withdraw();
//         (,,_dynamic,,,) = staking.getUserInfo(user);
//         assertEq(_dynamic, 0);
//         (,,_dynamic,,,) = staking.getUserInfo(prefixCode);
//         assertEq(_dynamic, 1e17);
//         vm.stopPrank();
//     }

// }
