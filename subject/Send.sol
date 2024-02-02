// SPDX-License-Identifier: GPL-3.0

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

contract Send{
    receive() external payable{}
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner,"Caller is not owner!");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function sendETH(address[] memory users) external onlyOwner(){

        for(uint i=0; i<users.length; i++){
            TransferHelper.safeTransferETH(users[i], 1e16);
        }
        
    }

    function withdraw() external onlyOwner() {
        TransferHelper.safeTransferETH(owner, address(this).balance);
    }

    function compute(address[] memory users) external pure returns(uint256){
        uint256 index = 0;
        for(uint i=0; i<users.length; i++){
            index++;
        }
        return index;
    }

}