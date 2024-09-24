// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { TransferHelper } from "./library/TransferHelper.sol"; 
import {IERC20} from "./interface/IERC20.sol";
import { UniswapV2Library } from "./library/UniswapV2Library.sol";

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable{

    enum Mark{
        INVAILD,
        ONE,
        TWO
    }

    enum Operate{
        Increase,
        reduce
    }

    struct Record{
        Operate operate;
        Mark    mark;
        address members;
        uint256 amount;
        uint256 time;
    }

    struct User{
        address   inviter;
        uint256   staking;
        uint256   dynamic;
        uint256   pending;
        uint256   stakingTime;
        address[] members;
        Record[]  records;
    }
    mapping(address => User) userInfo;
    address public token;
    address public prefixCode;
    uint256 public rate;
    uint256 public fee;
    uint256 public swapRate;
    address public recipient;
    address public usdt;
    address public subToken;

    receive() external payable{}

    function initialize(
        address _token, 
        address _prefixCode, 
        address _recipient,
        address _subToken,
        address _usdt,
        uint256 _rate,
        uint256 _fee,
        uint256 _swapRate
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        token = _token;
        prefixCode = _prefixCode;
        recipient = _recipient;
        subToken = _subToken;
        usdt = _usdt;
        rate = _rate;
        fee = _fee;
        swapRate = _swapRate;
    }

    function _authorizeUpgrade(address newImplementation)internal onlyOwner override{}

    function emergencyWithdraw(address _token, address _to) external onlyOwner{
        if(_token == address(0)) TransferHelper.safeTransferETH(_to, address(this).balance);
        else TransferHelper.safeTransfer(_token, _to, IERC20(_token).balanceOf(address(this)));
    }

    function setConfig(uint256 _rate, uint256 _fee) external onlyOwner{
        rate = _rate;
        fee = _fee;
    }

    function setSubToken(address _subToken) external onlyOwner{
        subToken = _subToken;
    }   

    function invite(address _inviter) external {
        bool valid= (_inviter != msg.sender) || (userInfo[msg.sender].inviter == address(0));
        require(valid, "ERROR_INVITER.");
        if(_inviter != prefixCode) require(userInfo[_inviter].staking >= 1e17,"NOT_HAS_INVITE_PERMIT.");
        userInfo[msg.sender].inviter = _inviter;
        userInfo[_inviter].members.push(msg.sender);
    }

    
    function getUserIncome(address _member) public view returns(uint256){
        User storage user = userInfo[_member];
        return ((block.timestamp - user.stakingTime) * (user.staking + user.dynamic) * rate + user.pending) / 1e18;
    }

    function updateRewards(address _member) internal{
        userInfo[_member].pending = getUserIncome(_member) * 1e18;
        userInfo[_member].stakingTime = block.timestamp;
    }


    function provide(uint256 _amount) external{
        User storage user = userInfo[msg.sender];
        require(user.inviter != address(0) && _amount >= 1e17 && _amount <= 1e18,"NOT_PROVIDE_PERMIT.");
        TransferHelper.safeTransferFrom(token, msg.sender, recipient, _amount);
        TransferHelper.safeTransferFrom(token, recipient, address(this), _amount);
        updateRewards(msg.sender);
        user.staking += _amount;
        synchronize(Operate.Increase, msg.sender, _amount);
    }

    function synchronize(Operate operate, address _member, uint256 _amount) internal{
        address _loop = userInfo[_member].inviter;
        for(uint i=0; i<2 && _loop != address(0); i++){
            updateRewards(_loop);
            User storage user = userInfo[_loop];
            uint256 _dynamic;
            if(i==0){
                user.records.push(Record(operate, Mark.ONE, _member, _amount, block.timestamp));
                _dynamic = _amount * 10 / 100;   
            }else{
                user.records.push(Record(operate, Mark.TWO, _member, _amount, block.timestamp));
                _dynamic = _amount * 5 / 100;
            }
            if(operate == Operate.Increase) user.dynamic += _dynamic;
            if(operate == Operate.reduce && user.dynamic >= _dynamic){
                user.dynamic -= _dynamic;
                if(user.dynamic < _dynamic) user.dynamic = 0;
            } 
            _loop = userInfo[_loop].inviter;
        } 
    }

    function withdraw() external{
        User storage user = userInfo[msg.sender];
        require(user.staking > 0,"ERROR_AMOUNT.");
        updateRewards(msg.sender);

        TransferHelper.safeTransfer(token, recipient, user.staking);
        TransferHelper.safeTransferFrom(token, recipient, msg.sender, user.staking * fee / 100);

        synchronize(Operate.reduce, msg.sender, user.staking);
        user.staking = 0;
        user.dynamic = 0;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function claim() external {
        require(!isContract(msg.sender),"ERROR_RECIPIENT.");
        require(getUserIncome(msg.sender) > 0,"ERROR_AMOUNT.");
        updateRewards(msg.sender);
        uint256 reward = getUserIncome(msg.sender);
        // TransferHelper.safeTransferETH(msg.sender, reward);
        TransferHelper.safeTransfer(subToken, msg.sender, reward);
        reward = 0;
        userInfo[msg.sender].pending = 0;
    }

    function getUserInfo(address member) external 
        view 
        returns(
        address _inviter,
        uint256 _staking,
        uint256 _dynamic,
        uint256 _income,
        address[] memory _members,
        Record[]  memory _records
        )
    {
        _inviter = userInfo[member].inviter;
        _staking = userInfo[member].staking;
        _dynamic = userInfo[member].dynamic;
        _income = getUserIncome(member);
        _members = userInfo[member].members;
        _records = userInfo[member].records;

    }

    function setSwapRate(uint256 _swapRate) external onlyOwner{
        swapRate = _swapRate;
    }
    
    function swap(uint256 _amount) external {
        
        TransferHelper.safeTransferFrom(subToken, msg.sender, address(this), _amount);
        uint256 swapAmount = 0;
        swapAmount = _amount * swapRate / 10000;
        TransferHelper.safeTransfer(usdt, msg.sender, swapAmount);
    }

}
