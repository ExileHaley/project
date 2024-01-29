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
    bool    public withdrawSwitch;

    struct User{
        uint256 staking;
        uint256 acquire;
    }

    mapping(address => User) public userInfo;

    uint256 public maxlimit = 3e18;
    uint256 public minlimit = 1e17;
    uint256 public rate = 2500;
    //subject:0x41b3a488c54ab541f9E1Dd460A28caBE08b7557d
    //receiver:0x48Ef30D8063FAd6204b344BD9ea80A9476345BB3
    constructor(address _subject,address _receiver){
        subject = _subject;
        receiver = _receiver;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Caller is not owner");
        _;
    }

    function provide(address _user, uint256 _amount) external payable{
        require(msg.value >= _amount,"Collection:Insufficient assets!");
        require(msg.value + userInfo[_user].staking <= maxlimit,"Collection:Maximum limit exceeded");
        require(msg.value >= 1e17,"Collection:Below minimum limit!");
        require(!withdrawSwitch,"Collection:Pause recharge!");
        TransferHelper.safeTransferETH(receiver, msg.value);
        userInfo[_user].staking += msg.value;
        userInfo[_user].acquire += (msg.value * rate);
    }  
    

    function withdraw(address _user, uint256 amount) external {
        require(withdrawSwitch,"Collection:Withdrawal not yet open!");
        require(userInfo[_user].acquire >= amount,"Collection:Insufficient subject assets!");
        userInfo[_user].acquire -= amount;
        TransferHelper.safeTransfer(subject, _user, amount);
    }

    function getMaximum(address _user) external view returns(uint256){
        return maxlimit - userInfo[_user].staking;
    }

    function setCurrency(address _subject) external onlyOwner{
        subject = _subject;
    }

    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    function setSwitch(bool _isSwitch) external onlyOwner{
        withdrawSwitch = _isSwitch;
    }

}
//collection:0xa5F55ac7D5d5a37b3CB3F9194958cF555bF04C39