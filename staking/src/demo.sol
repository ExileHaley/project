/**
 *Submitted for verification at BscScan.com on 2024-04-12
*/

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

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            )))));
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

}


contract StoreV1 is Store{

    enum Mark{
        INVAILD,
        ONE,
        TWO,
        THREE
    }

    enum Operate{
        Increase,
        reduce
    }

    struct Record{
        Operate operate;
        Mark    mark;
        address members;
        uint256 amount;
        uint256 time;
    }

    struct User{
        address   inviter;
        uint256   staking;
        uint256   dynamic;
        uint256   pending;
        uint256   stakingTime;
        address[] members;
        Record[]  records;
    }
    mapping(address => User) userInfo;

    address token;
    address public prefixCode;
    address uniswapV2Factory;
    address WETH;
    uint256 rewardRate;
    uint256 withdrawRate;
    uint256 minlimit;
    uint256 maxlimit;
    uint256 public fees;
}

contract StoreV2 is StoreV1{
    address public awardToken;
}

contract Staking is StoreV2{

    receive() external payable{}

    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(admin == msg.sender,"Caller is not owner!");
        _;
    }
    
    function init(address _award) external onlyOwner{
        awardToken = _award;
    }


    function setInfo(uint256 _withdraw,uint256 _reward,uint256 _min,uint256 _max)external onlyOwner(){
        withdrawRate = _withdraw;
        rewardRate = _reward * 1e15 / 86400;
        minlimit = _min * 1e18;
        maxlimit = _max * 1e18;
    }

    function invite(address _inviter) external{
        require(_inviter != msg.sender,"Invalid inviter address!");
        if(_inviter != prefixCode) require(userInfo[_inviter].staking > 0,"Not has invite permit!");
        require(userInfo[msg.sender].inviter == address(0),"Repeat operation!");
        userInfo[msg.sender].inviter = _inviter;
        userInfo[_inviter].members.push(msg.sender);
    }

    function getAmountOut(address tokenIn,address tokenOut,uint256 amountIn) public view returns(uint256 amountOut){
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, tokenIn, tokenOut);
        amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getUserIncome(address _member) public view returns(uint256){
        if (_getUserIncome(_member) > 0) {
            uint256 _amountBNB = getAmountOut(token, WETH, _getUserIncome(_member) / 1e18);
            return getAmountOut(WETH, awardToken, _amountBNB);
        }
        else return 0;
    }
    
    function _getUserIncome(address _member) public view returns(uint256){
        User storage user = userInfo[_member];
        return (block.timestamp - user.stakingTime) * (user.staking + user.dynamic) * rewardRate + user.pending;
    }

    function synchronize(Operate operate, address _member, uint256 _amount) internal{
        address _loop = userInfo[_member].inviter;
        for(uint i=0; i<3 && _loop != address(0); i++){
            updateRewards(_loop);
            User storage user = userInfo[_loop];
            uint256 _dynamic;
            if(i==0){
                user.records.push(Record(operate, Mark.ONE, _member, _amount, block.timestamp));
                _dynamic = _amount * 10 / 100;
                
            }else if(i==1){
                user.records.push(Record(operate, Mark.TWO, _member, _amount, block.timestamp));
                _dynamic = _amount * 6 / 100;
            }else{
                user.records.push(Record(operate, Mark.THREE, _member, _amount, block.timestamp));
                _dynamic = _amount * 4 / 100;
            }
            if(operate == Operate.Increase) user.dynamic += _dynamic;
            if(operate == Operate.reduce && user.dynamic >= _dynamic) user.dynamic -= _dynamic;
            _loop = userInfo[_loop].inviter;
        }
        
    }

    function updateRewards(address _member) internal{
        userInfo[_member].pending = _getUserIncome(_member);
        userInfo[_member].stakingTime = block.timestamp;
    }

    function provide(uint256 _amount) external{
        User storage user = userInfo[msg.sender];
        require(user.inviter != address(0),"Not provide permit!");
        require(_amount >= minlimit && _amount <= maxlimit,"provide amount error!");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), _amount);
        updateRewards(msg.sender);
        user.staking += _amount;
        synchronize(Operate.Increase, msg.sender, _amount);
    }

    function withdraw() external{
        User storage user = userInfo[msg.sender];
        require(user.staking > 0,"Withdraw amount error!");
        updateRewards(msg.sender);
        TransferHelper.safeTransfer(token, msg.sender, user.staking * (100 - withdrawRate) / 100);
        fees += (user.staking * withdrawRate / 100);
        synchronize(Operate.reduce, msg.sender, user.staking);
        user.staking = 0;
        user.dynamic = 0;
    }

    function claim() external {
        require(getUserIncome(msg.sender) > 0,"Claim amount error!");
        updateRewards(msg.sender);
        TransferHelper.safeTransfer(awardToken, msg.sender, getUserIncome(msg.sender));
        userInfo[msg.sender].pending = 0;
    }

    function managerWithdrawBaby(address _token,address _receiver,uint256 _amount) external onlyOwner(){
        TransferHelper.safeTransfer(_token, _receiver, _amount);
    }

    function managerWithdrawETH(address receiver,uint256 amount) external onlyOwner(){
        TransferHelper.safeTransferETH(receiver, amount);
    }


    function getUserInfo(address member) external 
        view 
        returns(
        address _inviter,
        uint256 _staking,
        uint256 _dynamic,
        uint256 _income,
        address[] memory _members,
        Record[]  memory _records
        )
    {
        _inviter = userInfo[member].inviter;
        _staking = userInfo[member].staking;
        _dynamic = userInfo[member].dynamic;
        _income = getUserIncome(member);
        _members = userInfo[member].members;
        _records = userInfo[member].records;

    }
}