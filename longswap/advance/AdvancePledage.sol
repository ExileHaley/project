// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract AdvanceStorage{
    address public admin;
    address public implementation;
}

contract Proxy is AdvanceStorage{
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

interface IPledage {
    function userInfo(address _user) external view returns(bool staking,uint256 time,uint256 num,address inv,uint256 income);
}

contract AdvanceStorageV1 is AdvanceStorage{

    struct Record{
        address beInvited;
        uint256 time;
    }

    struct User{
        uint256 amount;
        uint256 stakingTime;
        uint256 inviterNum;
        address inviter;
        uint256 income;
        bool    isMap;
    }

    struct UserRecord{
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
    address public beforePledage;
    address public dead;
    uint256 public baseRate;
}

contract AdvancePledage is AdvanceStorageV1{
    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(admin == msg.sender,"Caller is not admin");
        _;
    }

    function initialize(address _staking,address _before) external onlyAdmin(){
        dead = 0x000000000000000000000000000000000000dEaD;
        stakingToken = _staking;
        beforePledage = _before;
        baseRate = 10;
    }

    function setAddress(address _staking,address _earning) external onlyAdmin(){
        stakingToken = _staking;
        earningToken = _earning;
    }

    function setBase(uint256 _baseRate) external onlyAdmin(){
        baseRate = _baseRate;
    }

    function emergency(address token,address to) external  onlyAdmin(){
         (bool success,bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231,address(this)));
        require(success,"Recharge: failed to get balance.");
        uint256 amount = abi.decode(data, (uint256));
        if(amount > 0) TransferHelper.safeTransfer(token, to, amount);
    }

    function getUserInviteRecords(address _user) external view returns (Record[] memory){
        return recordInfos[_user];
    }

    function bind(address _inviter) external{
        User storage user = userInfo[msg.sender];
        require(user.inviter == address(0),"Duplicate binding is not allowed");
        user.inviter = _inviter;
    }

    function getIsMapping(address _user) public view returns(bool isMap){
       (bool staking,,uint256 num,address inv,) = IPledage(beforePledage).userInfo(_user);
       bool contion = staking || num > 0 || inv != address(0);
       User memory user = userInfo[_user];
       if (contion && !user.isMap) isMap = true;
    }

    function execute(address _user) external {
        User storage user = userInfo[_user];
        if(getIsMapping(_user)) {
            (bool staking,uint256 time,uint256 num,address inv,uint256 income) = IPledage(beforePledage).userInfo(_user);
            if(staking) {
                user.amount += 1e17;
                user.stakingTime = time;
            }
            user.inviterNum += num;
            user.inviter = inv;
            user.income = income;
            user.isMap = true;
        }

    }

    function provide(uint256 amount) external{
        User storage user = userInfo[msg.sender];
        if(getIsMapping(msg.sender)) require(user.isMap,"Please complete data mapping first");
        require(user.inviter != address(0),"Invalid inviter address");
        require(amount >= 1e17 && user.amount + amount <= 10e18,"Invalid provide amount");
        TransferHelper.safeTransferFrom(stakingToken, msg.sender, dead, amount);
        user.income = getUserIncome(msg.sender);
        user.amount += amount;
        user.stakingTime = block.timestamp;
        updateSuperior(msg.sender);
    }

    function updateSuperior(address _beInvited) internal{
        User memory user = userInfo[_beInvited];
        recordInfos[user.inviter].push(Record(_beInvited,block.timestamp));
        updateIncome(user.inviter);
        userInfo[user.inviter].inviterNum++;
    }

    function updateIncome(address _user) internal {
        uint256 _income = getUserIncome(_user);
        userInfo[_user].income = _income;
        userInfo[_user].stakingTime = block.timestamp;
    }

    function getUserIncome(address _user) public view returns(uint256 _income){
        User memory user = userInfo[_user];
        if(user.amount > 0){
            uint256 addBaseRate = (user.amount * baseRate) + user.inviterNum * 1e18;
            _income = (block.timestamp - user.stakingTime) * (addBaseRate / 86400) + user.income;
        }
    }

    function withdraw(address _user,uint256 _amount) external{
        uint256 _income = getUserIncome(_user);
        require(_income >= _amount, "Invalid withdraw amount");
        updateIncome(_user);
        userInfo[_user].income -= _amount;
        TransferHelper.safeTransfer(earningToken, _user, _amount);
    }


}


//online version
//logic:0x2Ce4EdcfC3Ce7D6f9151bd5d706A4A520d0E8a2e
//proxy:0x6757d5E4C081bFEC63C7A1761B576555Ff2068d0
//long:0xfc8774321ee4586af183baca95a8793530056353


//new online version
//long:0xfc8774321ee4586af183baca95a8793530056353
//before:0x6757d5E4C081bFEC63C7A1761B576555Ff2068d0
//proxy:0xfC0475CbF48f4754AC2b3F44CCF3d9F14590913c
//logic:0x3496BDBD57C79917bD6E58FFB3F161cC01c47eaC
