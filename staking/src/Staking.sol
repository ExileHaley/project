// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol"; 
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";

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
    address public uniswapV2Factory;
    uint256 public rate;
    uint256 public fee;
    //81018518518
    //69444444444
 
    address public WETH;
    address public recipient;

    receive() external payable{}

    function initialize(
        address _token, 
        address _prefixCode, 
        address _uniswapV2Factory, 
        address _recipient,
        address _WETH,
        uint256 _rate,
        uint256 _fee
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        token = _token;
        prefixCode = _prefixCode;
        uniswapV2Factory = _uniswapV2Factory;
        recipient = _recipient;
        WETH = _WETH;
        rate = _rate;
        fee = _fee;
    }

    function _authorizeUpgrade(address newImplementation)internal onlyOwner override{}

    function emergencyWithdraw(address _to) external onlyOwner{
        TransferHelper.safeTransferETH(_to, address(this).balance);
    }

    function setConfig(uint256 _rate, uint256 _fee) external onlyOwner{
        rate = _rate;
        fee = _fee;
    }

    function invite(address _inviter) external {
        bool valid= (_inviter != msg.sender) || (userInfo[msg.sender].inviter == address(0));
        require(valid, "ERROR_INVITER.");
        if(_inviter != prefixCode) require(userInfo[_inviter].staking >= 1e17,"NOT_HAS_INVITE_PERMIT.");
        userInfo[msg.sender].inviter = _inviter;
        userInfo[_inviter].members.push(msg.sender);
    }

    function getAmountOut(address tokenIn,address tokenOut,uint256 amountIn) public view returns(uint256 amountOut){
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, tokenIn, tokenOut);
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getUserIncome(address _member) public view returns(uint256 amountBNB){
        if (_getUserIncome(_member) > 0) {
            amountBNB = getAmountOut(token, WETH, _getUserIncome(_member) / 1e18);
        }
    }
    
    function _getUserIncome(address _member) public view returns(uint256){
        User storage user = userInfo[_member];
        return (block.timestamp - user.stakingTime) * (user.staking + user.dynamic) * rate + user.pending;
    }

    function updateRewards(address _member) internal{
        userInfo[_member].pending = _getUserIncome(_member);
        userInfo[_member].stakingTime = block.timestamp;
    }


    function provide(uint256 _amount) external{
        User storage user = userInfo[msg.sender];
        require(user.inviter != address(0) && _amount >= 1e17,"NOT_PROVIDE_PERMIT.");
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
        TransferHelper.safeTransferETH(msg.sender, reward);
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
}
