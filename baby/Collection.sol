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

contract StoreV1 is Store{
    
    struct Record{
        uint256 amountBNB;
        uint256 time;
    }

    struct User{
        uint256 amountBNB;
        uint256 amountToken;
        Record[] records;
    }

    mapping(address => User) userInfo;
    address token;
    uint256 maxlimit;
    uint256 rate;
    bool    public withSwitch;

}

contract Collection is StoreV1{
    receive() external payable {}

    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(admin == msg.sender,"Caller is not owner!");
        _;
    }
    //collection:
    //token:0xf079e0996aFe7A2f3B9165700c839f1110e8ddD9
    //rate:10
    //proxy:0x9e7C4B4f3cC97Dff91A842E5a478336306206064
    //collection:0x26AdFBdef9C883C7C50915CBE89AcF388fcE3044
    function init(address _token, uint256 _rate) external onlyOwner(){
        token = _token;
        rate = _rate;
        maxlimit = 1e18;
    }

    function switchWithdraw() external onlyOwner(){
        withSwitch = true;
    }

    function managerWithdrawToken(address receiver, uint256 amount) external onlyOwner(){
        TransferHelper.safeTransfer(token, receiver, amount);
    }

    function managerWithdrawETH(address receiver, uint256 amount) external onlyOwner(){
        TransferHelper.safeTransferETH(receiver, amount);
    }

    function getQuota(address member) public view returns(uint256){
        if(userInfo[member].amountBNB >= maxlimit) return 0;
        else return maxlimit - userInfo[member].amountBNB;
    }

    function provide(uint256 amount) external payable{
        require(amount <= getQuota(msg.sender) && amount >= 1e17 && msg.value >= amount,"Provide amount error");
        require(!withSwitch,"Provide state error");
        TransferHelper.safeTransferETH(address(this), msg.value);
        userInfo[msg.sender].amountToken += (amount * rate);
        userInfo[msg.sender].amountBNB += amount;
        userInfo[msg.sender].records.push(Record(amount,block.timestamp));
    }

    function claim(uint256 amount) external {
        require(amount <= userInfo[msg.sender].amountToken,"Claim amount error");
        require(withSwitch,"Claim state error");
        TransferHelper.safeTransfer(token, msg.sender, amount);
        userInfo[msg.sender].amountToken -= amount;
    }

    function getUserInfo(address member) external view returns(uint256 _bnb, uint256 _token, Record[] memory _records){
        _bnb = userInfo[member].amountBNB;
        _token = userInfo[member].amountToken;
        _records = userInfo[member].records;
    }

    function getCollectInfo() external view returns(uint256 _bnb,uint256 _token){
        _bnb = address(this).balance;
        _token = address(this).balance * rate;
    }
}