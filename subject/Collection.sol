// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract Collection{

    receive() external payable{}

    address public subject;
    address public owner;
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

    uint256 public maxlimit = 3e18;
    uint256 public minlimit = 1e17;
    uint256 public rate = 25000;

    //测试subject:0x417328A0c68Fc43c65ed15de5418FC9525837542
    //receiver:0x48Ef30D8063FAd6204b344BD9ea80A9476345BB3
    //collection:0x962c527a9Dc33fD010B617b6544aA5a1a5E59428
    //2024.02.01 13:30:00  1706772600
    //2024.02.09 18:30:00  1707474600
    constructor(address _subject,address _receiver){
        subject = _subject;
        receiver = _receiver;
        owner = msg.sender;
        startTime = block.timestamp;

        endTime = block.timestamp + (86400 * 4);
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Caller is not owner");
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
        owner = _owner;
    }

    function setTime(uint256 _start,uint256 _end) external onlyOwner{
        startTime = _start;
        endTime = _end;
    }

}
