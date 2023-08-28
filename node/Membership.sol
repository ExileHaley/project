// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MemberStor{
    address public admin;
    address public implementation;
}

contract Proxy is MemberStor{
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


contract MemberStorV1 is MemberStor{
    //`Team info list`
    struct TeamReward{
        address member;
        uint256 amount;
        uint256 time;
    }
    mapping(address => TeamReward[]) teamRewardInfo;
    //`user info list`
    mapping(address => bool) public isVip;
    mapping(address => bool) public isVips;
    mapping(address => address) public inviter;
    mapping(address => uint256) public invitesNum;
    mapping(address => uint256) public totalTeamReward;
    //`pool info list`
    address   public initialInviter;
    address   public gasFeesReceiver;
    address   public token;
    address   public thirtyPercent;
    address   public fourPercent;
    address   public operator;
    uint256   public vipGasFees;
    uint256   public tokenPrice;
    uint256   public fixedPrice;
    //`return user info`
    struct User{
        bool isp;
        bool isps;
        address inv;
        uint256 invNum;
        uint256 totalTR;
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

contract Membership is MemberStorV1{

    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner(){
        require(admin == msg.sender,"Membership:Caller is not owner");
        _;
    }

    modifier onlyOperator(){
        require(operator == msg.sender,"Membership:Caller is not owner");
        _;
    }

    function initialize(
        address _initialInviter,address _gasFeesReceiver,address _token,
        address _thirtyPercent,address _fourPercent,address _operator,uint256 _tokenPrice
    ) external onlyOwner{
        initialInviter = _initialInviter;
        gasFeesReceiver = _gasFeesReceiver;
        token = _token;  
        thirtyPercent = _thirtyPercent;
        fourPercent = _fourPercent;
        vipGasFees = 8e15;
        fixedPrice = 500e18;
        tokenPrice = _tokenPrice;
        operator = _operator;
    }
    
    function bind(address _inviter) external{
        require(initialInviter != address(0), "Membership:Zero initial address");
        require(_inviter != address(0) && inviter[msg.sender] == address(0),"Membership:Invalid inviter address");
        if(initialInviter != _inviter){
            require(isVip[_inviter], "Membership:Not eligible");
        }
        inviter[msg.sender] = _inviter;
    }

    function getAmountIn() public view returns(uint256){
        return fixedPrice / tokenPrice * 100;
    }

    function purchasingVip(address _user,uint256 _amount) external payable{
        if(_user != initialInviter) {
            require(inviter[_user] != address(0),"Membership:The invitation address must be bound");
        }
        require(_amount >= getAmountIn(),"Membership:Invalid purchasing amount");
        require(msg.value >= vipGasFees,"Membership:Insufficient expenses");
        TransferHelper.safeTransferETH(address(this), msg.value);
        uint256 reward = _amount * 66 / 100;
        uint256 toThirty = _amount * 30 / 100;
        TransferHelper.safeTransferFrom(token, _user, address(this), reward);
        TransferHelper.safeTransferFrom(token, _user, thirtyPercent, toThirty);
        TransferHelper.safeTransferFrom(token, _user, fourPercent, _amount - reward - toThirty); 
        isVip[_user] = true;

        if(inviter[_user] != address(0)){
            updateInviter(inviter[_user], _amount);
        }
        distribute(_user, _amount); 
    }

    function updateInviter(address _inv,uint256 _amount) internal{
        totalTeamReward[_inv] = totalTeamReward[_inv] + _amount * 20 / 100;
        invitesNum[_inv] += 1;
        if(invitesNum[_inv] >= 2) isVips[_inv] = true;
    }

    function distribute(address _user,uint256 _amount) internal{
        address level = lookFor(_user);
        if(level != address(0)){
            totalTeamReward[level] = totalTeamReward[level] + (_amount * 40 / 100);
            teamRewardInfo[level].push(TeamReward(_user,_amount * 40 / 100,block.timestamp));
        }
        
        address upLevel = lookFor(level);
        if(upLevel != address(0)){
            totalTeamReward[upLevel] = totalTeamReward[upLevel] + (_amount * 6 / 100);
            teamRewardInfo[upLevel].push(TeamReward(_user,_amount * 6 / 100,block.timestamp));
        }
        
    }

    function lookFor(address _user) internal view returns(address){
        address invAddr = inviter[_user];
        while (!isVips[invAddr] && invAddr != address(0)){
            invAddr = inviter[invAddr];
        }
        return invAddr;
    }

    function claim(address _user,uint256 _amount) external{
        require(totalTeamReward[_user] >= _amount,"Membership:Invalid claim amount");
        TransferHelper.safeTransfer(token, _user, _amount);
        totalTeamReward[_user] -= _amount;
    }
    
    function getUserInfo(address _user) external view returns(User memory){
        return User(isVip[_user],isVips[_user],inviter[_user],invitesNum[_user],totalTeamReward[_user]);
    }
    
    function getUserTeamInfo(address _user) external view returns(TeamReward[] memory){
        return teamRewardInfo[_user];
    }

    
    function updatePrice(uint256 _price) external onlyOperator{
        tokenPrice = _price;
    }

    function setOperator(address _operator) external onlyOwner{
        operator = _operator;
    }

    function updatePercentReceiver(address _thirtyPercent,address _fourPercent) external onlyOwner{
        thirtyPercent = _thirtyPercent;
        fourPercent = _fourPercent;
    }

    function setAdmin(address _admin) external  onlyOwner{
        admin = _admin;
    }

    function updateGasInfo(address _gasReceiver,uint256 _gasFee) external  onlyOwner{
        gasFeesReceiver = _gasReceiver;
        vipGasFees = _gasFee;
    }

}

