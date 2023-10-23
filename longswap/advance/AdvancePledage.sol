// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Advance{
    address public admin;
    address public implementation;
}

contract Proxy is Advance{
    receive() external payable {}
    constructor() {
        admin = msg.sender;
    }

    modifier onlyOwner(){
        require(admin == msg.sender,"Proxy:Caller is not owner");
        _;
    }

    function _updateAdmin(address _admin) public onlyOwner{
        admin = _admin;
    }

    function setImplementation(address newImplementation) public onlyOwner{  
        implementation = newImplementation;
    }

    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}


library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract AdvanceV1 is Advance{

    struct Record{
        address beInvited;
        uint256 time;
    }

    struct User{
        bool    whetherStaking;
        uint256 stakingTime;
        uint256 inviterNum;
        address inviter;
        uint256 income;
    }

    mapping(address => Record[]) public recordInfos;
    mapping(address => User) public userInfo;
    address public stakingToken;
    address public earningToken;
    address public initialInviter;
    uint256 public baseRate;
    uint256 public stakingBase;
}

contract AdvancePledage is AdvanceV1{
    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(admin == msg.sender,"Caller is not admin");
        _;
    }

    function initialize(address _staking,address _initial) external onlyAdmin(){
        stakingToken = _staking;
        initialInviter = _initial;
        baseRate = 10e18;
        stakingBase = 1e17;
    }

    function setAddress(address _staking,address _earning) external onlyAdmin(){
        stakingToken = _staking;
        earningToken = _earning;
    }

    function setBase(uint256 _baseRate,uint256 _stakingBase) external onlyAdmin(){
        baseRate = _baseRate;
        stakingBase = _stakingBase;
    }

    function bind(address _inviter) external{
        if (_inviter != initialInviter) require(userInfo[_inviter].whetherStaking != false,"Not eligible for invitation");
        User storage user = userInfo[msg.sender];
        require(user.inviter == address(0),"Duplicate binding is not allowed");
        user.inviter = _inviter;
    }

    function provide() external {
        User storage user = userInfo[msg.sender];
        require(user.inviter != address(0),"Invalid inviter address");
        require(user.whetherStaking != true,"Duplicate staking is not allowed");
        TransferHelper.safeTransferFrom(stakingToken, msg.sender, address(this), stakingBase);
        user.whetherStaking = true;
        user.stakingTime = block.timestamp;
        updateSuperior(msg.sender);
    }

    function updateSuperior(address _beInvited) internal{
        User memory user = userInfo[_beInvited];
        recordInfos[user.inviter].push(Record(_beInvited,block.timestamp));
        updateIncome(user.inviter);
        userInfo[user.inviter].inviterNum++;
    }

    function updateIncome(address _upper) internal {
        uint256 _income = getUserIncome(_upper);
        userInfo[_upper].income = _income;
        userInfo[_upper].stakingTime = block.timestamp;
    }

    function getUserIncome(address _user) public view returns(uint256 _income){
        User memory user = userInfo[_user];
        if(user.whetherStaking != false){
            _income = (block.timestamp - user.stakingTime) * (baseRate / 86400) *(user.inviterNum + 1) + user.income;
        }
    }

    function withdraw(address _user,uint256 _amount) external{
        uint256 _income = getUserIncome(_user);
        require(_income >= _amount, "Invalid withdraw amount");
        updateIncome(_user);
        userInfo[_user].income -= _amount;
        // TransferHelper.safeTransfer(earningToken, _user, _amount);
    }
}

//logic:0x17d146a8CDC8A8EefcceC1bcb23B0452A2288dc6
//proxy:0x7eA65FcefFED446F452799d93654A921B8905D02

//long:0xfc8774321ee4586af183baca95a8793530056353
//init:0x7E0134FE4992D9A3ad519164C5AFF691112b7bd2