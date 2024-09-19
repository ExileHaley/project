// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {UniswapV2Library} from "./library/UniswapV2Library.sol";
import {TransferHelper} from "./library/TransferHelper.sol";
import {IUniswapV2Router02} from "./interface/IUniswapV2Router.sol";
import {IERC20} from "./interface/IERC20.sol";
import {IUniswapV2Factory} from "./interface/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interface/IUniswapV2Pair.sol";
import {ReentrancyGuard} from "./library/ReentrancyGuard.sol";

contract Liquidity is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{

    struct Record{
        address members;
        uint256 amountToken;
        uint256 amountUsdt;
        uint256 liquidity;
        uint256 time;
    }

    struct User{
        address   inviter;
        uint256   staking;
        uint256   lpAmount;
        uint256   value;
        uint256   dynamic;
        uint256   pending;
        uint256   stakingTime;
        uint256   extracted;
        address[] members;
        Record[]  records;
    }
    mapping(address => User) userInfo;

    uint256 public rate;
    address token;
    address subToken;
    address public prefixCode;
    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public constant uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    receive() external payable{}

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    function initialize(
        address _token,
        address _subToken,
        address _prefixCode
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        token = _token;
        subToken = _subToken;
        prefixCode = _prefixCode;
        rate = uint256(10e18) / 86400;
    }

    function _authorizeUpgrade(address newImplementation)internal onlyOwner override{}

    function emergencyWithdraw(address _token, address _to) external onlyOwner{
        if(_token == address(0)) TransferHelper.safeTransferETH(_to, address(this).balance);
        else TransferHelper.safeTransfer(_token, _to, IERC20(_token).balanceOf(address(this)));
    }

    function setConfig(address _token, address _subToken, address _prefixCode) external onlyOwner{
        token = _token;
        subToken = _subToken;
        prefixCode = _prefixCode;
    }

    function setRate(uint256 _dayRate) external onlyOwner{
        rate = _dayRate / 86400;
    }

    function invite(address _inviter) external {
        bool valid= (_inviter != msg.sender) || (userInfo[msg.sender].inviter == address(0));
        require(valid, "ERROR_INVITER.");
        if(_inviter != prefixCode) require(userInfo[_inviter].staking >0, "NOT_HAS_INVITE_PERMIT.");
        userInfo[msg.sender].inviter = _inviter;
        userInfo[_inviter].members.push(msg.sender);
    }

    function getQuoteAmount(uint256 amountToken) public view returns(uint256 amountUsdt){
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, token, usdt);
        amountUsdt = UniswapV2Library.quote(amountToken, reserveA, reserveB);
    }

    function getUserIncome(address member) public view returns(uint256){
        return _getUserIncome(member) / 1e18;
    }

    function _getUserIncome(address member) internal view returns(uint256){
        User storage user = userInfo[member];
        uint256 _currentIncomeWithDecimals = (block.timestamp - user.stakingTime) * (user.staking + user.dynamic) * rate + user.pending;
        return _currentIncomeWithDecimals;
    }


    function updateRewards(address member) internal{
        userInfo[member].pending = _getUserIncome(member);
        userInfo[member].stakingTime = block.timestamp;
    }

    /********************************************************pull***********************************************************/
    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(uniswapV2Factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(uniswapV2Factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /********************************************************pull***********************************************************/


    function provide(uint256 amountToken) external nonReentrant(){
        User storage user = userInfo[msg.sender];
        require(user.inviter != address(0), "NOT_ADD_LIQUIDITY_PERMIT.");
        uint256 mustUsdt = getQuoteAmount(amountToken);
        (uint256 _amountToken, uint256 _usdtAmount, uint256 _liquidityAmount) = addLiquidity(
            token, 
            usdt, 
            amountToken, 
            mustUsdt, 
            0, 
            0, 
            address(this), 
            block.timestamp
        );

        updateRewards(msg.sender);

        user.staking += _amountToken;
        user.lpAmount += _liquidityAmount;
        user.value += (_usdtAmount * 2);

        upgrade(msg.sender, _amountToken, _usdtAmount, _liquidityAmount);

    }

    function upgrade(address member, uint256 amountToken, uint256 amountUsdt, uint256 liquidity) internal{
        address upper = userInfo[member].inviter;
        if (upper != address(0)){
            userInfo[upper].records.push(Record(member, amountToken, amountUsdt, liquidity, block.timestamp));
            updateRewards(upper);
            userInfo[upper].dynamic += (amountToken * 1 / 100);
        }
    }

    function claim() external{
        require(getUserIncome(msg.sender) > 0,"ERROR_AMOUNT.");
        updateRewards(msg.sender);
        uint256 reward = getUserIncome(msg.sender);
        TransferHelper.safeTransfer(subToken, msg.sender, reward);
        reward = 0;
        userInfo[msg.sender].extracted += getUserIncome(msg.sender);
        userInfo[msg.sender].pending = 0;
    }

    function getUserInfo(address member) external view 
    returns(
        address   inviter,
        uint256   staking,
        uint256   lpAmount,
        uint256   value,
        uint256   dynamic,
        uint256   extracted,
        address[] memory members,
        Record[]  memory records
    )
    {
        User memory user = userInfo[member];
        inviter = user.inviter;
        staking = user.staking;
        lpAmount = user.lpAmount;
        value = user.value;
        dynamic = user.dynamic;
        extracted = user.extracted;
        members = user.members;
        records = user.records;
    }
}