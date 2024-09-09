// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {Staking} from "../src/Staking.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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
