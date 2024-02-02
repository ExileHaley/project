// SPDX-License-Identifier: GPL-3.0

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
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract StoreV1 is Store{
    address public subject;
    address public receiver;
    uint256 public startTime;
    uint256 public endTime;

    struct User{
        uint256 staking;
        uint256 acquire;
    }
    mapping(address => User) public userInfo;

    struct Record{
        address member;
        uint256 amount;
        uint256 time;
    }
    Record[] records;
    uint256 public maxlimit;
    uint256 public minlimit;
    uint256 public rate;
}


contract Collection is StoreV1{
    receive() external payable{}

    //正式subject:0x77E34975aBF6432Ed2029Cf7ea571C6ad678cF4F
    //receiver:0x48Ef30D8063FAd6204b344BD9ea80A9476345BB3
    //2024.02.01 13:30:00  1706772600
    //2024.02.09 18:30:00  1707480120
    constructor(){  
        admin = msg.sender;
    }

    function initialize(address _subject,address _receiver,uint256 _start,uint256 _end) external  onlyOwner{
        subject = _subject;
        receiver = _receiver;
        startTime = _start;
        endTime = _end;
        maxlimit = 3e18;
        minlimit = 1e18;
        rate = 25000;
    }

    modifier onlyOwner() {
        require(msg.sender == admin,"Caller is not owner");
        _;
    }

    function provide(address _user, uint256 _amount) external payable{
        require(msg.value >= _amount,"Collection:Insufficient assets!");
        require(msg.value + userInfo[_user].staking <= maxlimit,"Collection:Maximum limit exceeded");
        require(msg.value >= 1e17,"Collection:Below minimum limit!");
        require(block.timestamp >= startTime && block.timestamp < endTime,"Collection:Pause recharge!");
        TransferHelper.safeTransferETH(receiver, msg.value);
        userInfo[_user].staking += msg.value;
        userInfo[_user].acquire += (msg.value * rate);
        records.push(Record(_user, _amount, block.timestamp));
    }  
    
    function withdraw(address _user, uint256 amount) external {
        require(block.timestamp >= endTime,"Collection:Withdrawal not yet open!");
        require(userInfo[_user].acquire >= amount,"Collection:Insufficient subject assets!");
        userInfo[_user].acquire -= amount;
        TransferHelper.safeTransfer(subject, _user, amount);
    }

    function getMaximum(address _user) external view returns(uint256){
        return maxlimit - userInfo[_user].staking;
    }

    function getRecords() external view returns (Record[] memory) {
        uint256 totalRecords = records.length;
        uint256 recordsToFetch = totalRecords < 200 ? totalRecords : 200;
        Record[] memory latestRecords = new Record[](recordsToFetch);

        uint256 index = 0;
        for (uint256 i = totalRecords; i > 0 && index < recordsToFetch; i--) {
            latestRecords[index] = records[i - 1];
            index++;
        }

        return latestRecords;
    }


    function getCount() external view returns(uint256 count){
        if(endTime >= block.timestamp) count = endTime - block.timestamp;
    }

    function setCurrency(address _subject) external onlyOwner{
        subject = _subject;
    }

    function setOwner(address _owner) external onlyOwner{
        admin = _owner;
    }

    function setTime(uint256 _start,uint256 _end) external onlyOwner{
        startTime = _start;
        endTime = _end;
    }

    function setReceiver(address _receiver) external  onlyOwner{
        receiver = _receiver;
    }

    function managerWithdraw(address to,uint256 amount) external  onlyOwner(){
        TransferHelper.safeTransfer(subject, to, amount);
    }

}

//proxy:0x56521f11C21b7f0000DCc5FDB10f9507F1780E84
//collection:0xbF879c41d82e2BC3321b0Dbc4a40A9880316eab4
