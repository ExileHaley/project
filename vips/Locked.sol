// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Locked{
    address token;
    uint256 startTime;
    uint256 lockedTime = 157680000;
    address beneficiary;

    constructor(address _token,address _beneficiary){
        token = _token;
        beneficiary = _beneficiary;
        startTime = block.timestamp;
    }


    function getExtractableAmount() public view returns(uint256 extractable){
        if(block.timestamp >= startTime + lockedTime){
            (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)",address(this)));
            require(success,"Static call failed");
            extractable = abi.decode(data,(uint256));
        } 
    }


    function release() external {
        uint256 amount = getExtractableAmount();
        if(amount > 0){
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, beneficiary, amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
    
}
