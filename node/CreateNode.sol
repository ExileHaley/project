// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract NodeStor{
    address public admin;
    address public implementation;
}

contract Proxy is NodeStor{
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


contract NodeStorV1 is NodeStor{
    struct Award{
        address recommend;
        uint256 amount;
        uint256 awardTime;
    }

    mapping(address => uint256) invitesNum; //邀请人数
    mapping(address => bool)    isPurchasing; //是否购买节点
    mapping(address => bool)    isLevel; //是否有级别
    mapping(address => address) inviter; //邀请人
    mapping(address => Award[]) teamInfo; //团队信息
    mapping(address => uint256) totalAward; //总收益

    address   initInviter;//初始邀请人

    address public gasSotr;
    uint256 public gasFees;
    address public token;
    address public marketing;
    address public fundation;
    uint256 public tokenPrice;
    uint256 public fixedPrice;

    struct UserInfo{
        address inv;
        uint256 invNum;
        uint256 tAward;
        bool    isp;
        bool    isn;
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

contract CreateNode is NodeStorV1{
    
    constructor(){
        admin = msg.sender;
    }

    function bind(address _inviter) external{
        require(_inviter != address(0) && inviter[msg.sender] == address(0),"CreateNode:Invalid inviter address");
        if(initInviter != _inviter){
            require(isPurchasing[_inviter], "CreateNode:Not eligible");
        }
        inviter[msg.sender] = _inviter;
    }

    function purchasingNode(address _user,uint256 _amount) external payable{
        if(_user != initInviter) {
            require(inviter[_user] != address(0),"CreateNode:The invitation address must be bound");
        }
        require(_amount >= getAmountIn(),"CreateNode:Invalid purchasing amount");
        require(msg.value >= gasFees,"CreateNode:Insufficient expenses");
        TransferHelper.safeTransferETH(address(this), msg.value);
        uint256 reward = _amount * 66 / 100;
        uint256 toMarket = _amount * 30 / 100;
        TransferHelper.safeTransferFrom(token, _user, address(this), reward);
        TransferHelper.safeTransferFrom(token, _user, marketing, toMarket);
        TransferHelper.safeTransferFrom(token, _user, fundation, _amount - reward - toMarket); 
        isPurchasing[_user] = true;
        if(inviter[_user] != address(0)){
            updateInviter(inviter[_user], _amount);
        }
        address level = lookFor(_user);
        totalAward[level] = totalAward[level] + (_amount * 40 / 100);
        teamInfo[level].push(Award(_user,_amount * 40 / 100,block.timestamp));

        address upLevel = lookFor(level);
        totalAward[upLevel] = totalAward[upLevel] + (_amount * 6 / 100);
        teamInfo[upLevel].push(Award(_user,_amount * 6 / 100,block.timestamp));
    }

    function updateInviter(address _inv,uint256 _amount) internal{
        totalAward[_inv] = totalAward[_inv] + _amount * 20 / 100;
        invitesNum[_inv] += 1;
        if(invitesNum[_inv] >= 3) isLevel[_inv] = true;
    }

    function lookFor(address _user) internal view returns(address){
        address inv = inviter[_user];
        while (!isLevel[inv]){
            inv = inviter[inv];
        }
        return inv;
    }

    function getAmountIn() public view returns(uint256){
        return fixedPrice / tokenPrice;
    }

    function getUserInfo(address _user) external view returns(UserInfo memory){
        return UserInfo(inviter[_user],invitesNum[_user],
                            totalAward[_user],isPurchasing[_user],isLevel[_user]);
    }

    function claim(address _user,uint256 _amount) external{
        require(totalAward[_user] >= _amount,"CreateNode:Invalid claim amount");
        TransferHelper.safeTransfer(token, _user, _amount);
        totalAward[_user] -= _amount;
    }

}
