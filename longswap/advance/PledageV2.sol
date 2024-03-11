/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Store{
    address public admin;
    address public implementation;
}

contract Proxy is Store{
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
    function userInfo(address _user) external view returns(uint256 amount,uint256 time,uint256 num,address inv,uint256 income,bool isMap);
}

contract PledageStoreV1 is Store{

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

    mapping(address => Record[]) public recordInfos;
    mapping(address => User) public userInfo;
    address public stakingToken;
    address public earningToken;
    address public beforePledage;
    address public dead;
    uint256 public baseRate;

    uint256 public totalStaking;
}

contract PledageV1 is PledageStoreV1{

    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(admin == msg.sender,"Caller is not admin");
        _;
    }
    //before:0xfC0475CbF48f4754AC2b3F44CCF3d9F14590913c
    //earning:0xf079e0996afe7a2f3b9165700c839f1110e8ddd9
    //testAddress:0xB82A403e9BDc58b121Ec839C269bbcC4eeCf7bD9

    //pledage:0x42A047cC6eC8cCDAd8204Dc3f3D21Fe2620A293b
    //proxy:0x3dfBB78b66f737a01527976d9213D79c33fB8aEc
    // ### 旧版本合约地址(废弃)
    // ### pledage contract:0xfC0475CbF48f4754AC2b3F44CCF3d9F14590913c
    // ### long token:0xfc8774321ee4586af183baca95a8793530056353
    function initialize(address _earning,address _before) external onlyAdmin(){
        earningToken = _earning;
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

    function getIsMapping(address _user) public view returns(bool isMap){
       (uint256 amount,,uint256 num,address inv,,) = IPledage(beforePledage).userInfo(_user);
       bool contion = amount > 0 || num > 0 || inv != address(0);
       User memory user = userInfo[_user];
       if (contion && !user.isMap) isMap = true;
    }

    function execute(address _user) external {
        User storage user = userInfo[_user];
        if(getIsMapping(_user)) {
            (uint256 _amount,,uint256 _num,address _inv,,) = IPledage(beforePledage).userInfo(_user);
            user.amount += _amount;
            totalStaking += _amount;
            user.stakingTime = block.timestamp;
            user.inviterNum += _num;
            user.inviter = _inv;
            Record[] memory records = PledageV1(beforePledage).getUserInviteRecords(_user);
            for (uint i=0; i<records.length; i++){
                recordInfos[_user].push(records[i]);
            }
            user.isMap = true;
        }
    }

    function updateIncome(address _user) internal {
        uint256 _income = getUserIncome(_user);
        userInfo[_user].income = _income;
        userInfo[_user].stakingTime = block.timestamp;
    }

    function getUserIncome(address _user) public view returns(uint256 _income){
        User memory user = userInfo[_user];
        if(user.amount > 0){
            uint256 addBaseRate = user.amount * baseRate / 1000;
            _income = (block.timestamp - user.stakingTime) * (addBaseRate / 86400) + user.income;
        }
    }

    function claim(address _user,uint256 _amount) external{
        uint256 _income = getUserIncome(_user);
        require(_income >= _amount, "Invalid withdraw amount");
        updateIncome(_user);
        userInfo[_user].income -= _amount;
        TransferHelper.safeTransfer(earningToken, _user, _amount);
    }

}