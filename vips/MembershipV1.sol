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


contract MemberStorV1 is MemberStor{
    enum Express{direct,vips,sameLevel}
    //`Team info list`
    struct TeamReward{
        address partner;
        uint256 rewardValue;
        uint256 rewardTime;
        Express express;
    }

    struct ClaimRecords{
        address receiver;
        uint256 amount;
        uint256 claimTime;
    }
    mapping(address => TeamReward[]) teamRewards;
    mapping(address => ClaimRecords[]) claimRecords;
    //`user info list`
    mapping(address => bool) public isVip;
    mapping(address => bool) public isVips;
    mapping(address => address) public inviter;
    mapping(address => uint256) public invitesNum;
    mapping(address => uint256) public totalTeamReward;
    //`pool info list` must be init
    address   public initialInviter;
    address   public uniswapV2Factory;
    address   public token;
    address   public usdt;
    address   public twentyPercent;
    address   public tenPercent;
    address   public fourPercent;
    uint256   public fixedPrice;
    uint8     public maxLooked;
    //`return user info`
    struct User{
        bool isp;
        bool isps;
        address inv;
        uint256 invNum;
        uint256 totalTR;
    }

}

contract MemberShip is MemberStorV1{
    
    constructor(){
        admin = msg.sender;
    }

    modifier onlyOwner(){
        require(admin == msg.sender,"Membership:Caller is not owner");
        _;
    }
    
    function initialize(
        address _token,address _initialInviter,
        address _fourPercent,address _tenPercent,address _twentyPercent
    ) external onlyOwner{
        initialInviter = _initialInviter;
        uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        token = _token;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        tenPercent = _tenPercent;
        fourPercent = _fourPercent;
        twentyPercent = _twentyPercent;
        fixedPrice = 500e18;
        maxLooked = 30;
    }

    function bind(address _inviter) external{
        require(initialInviter != address(0), "Membership:Zero initial address");
        if(initialInviter != _inviter){
            require(isVip[_inviter], "Membership:Not eligible");
            require(_inviter != msg.sender,"Membership:Only vip");
        }
        inviter[msg.sender] = _inviter;
    }

    function getAmountOut() public view returns(uint256 amountOut){
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, usdt, token);
        amountOut = UniswapV2Library.getAmountOut(fixedPrice, reserveIn, reserveOut);
    }

    function purchasingVip(address _user) external{
        require(inviter[_user] != address(0),"Membership:The invitation address must be bound");
        require(_user == msg.sender,"Membership:Invalid operator");

        uint256 _amount = getAmountOut();
        require(_amount > 0,"Membership:Invalid purchasing amount");

        uint256 reward = _amount * 66 / 100;
        uint256 toTwenty = _amount * 20 / 100;
        uint256 toTen = _amount * 10 / 100;

        TransferHelper.safeTransferFrom(token, _user, address(this), reward);
        TransferHelper.safeTransferFrom(token, _user, twentyPercent, toTwenty);
        TransferHelper.safeTransferFrom(token, _user, tenPercent, toTen);
        TransferHelper.safeTransferFrom(token, _user, fourPercent, _amount - reward - toTwenty - toTen);  

        if(!isVip[_user]){
            updateInviter(_user,_amount);
            isVip[_user] = true;
        }
    }

    function updateInviter(address _user,uint256 _amount)internal{
        address _direct = inviter[_user];
        invitesNum[_direct] += 1;
        if(invitesNum[_direct] >= 3 && !isVips[_direct]) isVips[_direct] = true; 

        totalTeamReward[_direct] = totalTeamReward[_direct] + (_amount * 20 / 100);
        teamRewards[_direct].push(TeamReward(_user, _amount * 20 / 100, block.timestamp, Express.direct));

        if(isVips[_direct]){
            totalTeamReward[_direct] = totalTeamReward[_direct] + (_amount * 40 / 100);
            teamRewards[_direct].push(TeamReward(_user,_amount * 40 / 100,block.timestamp,Express.vips));
            address _degrees = inviter[_direct];
            if(_degrees != address(0)){
                totalTeamReward[_degrees] = totalTeamReward[_degrees] + (_amount * 6 / 100);
                teamRewards[_degrees].push(TeamReward(_user, _amount * 6 / 100, block.timestamp, Express.sameLevel));
            }
        }else{
            distribute(_user, _amount);
        }
    }

    function distribute(address _user,uint256 _amount) internal{
        address firstVips = lookFor(_user);
        if(isVips[firstVips]){
            totalTeamReward[firstVips] = totalTeamReward[firstVips] + (_amount * 40 / 100);
            teamRewards[firstVips].push(TeamReward(_user,_amount * 40 / 100,block.timestamp,Express.vips));
            address inviterOffirstVips = inviter[firstVips];
            if(inviterOffirstVips != address(0)){
                totalTeamReward[inviterOffirstVips] = totalTeamReward[inviterOffirstVips] + (_amount * 6 / 100);
                teamRewards[inviterOffirstVips].push(TeamReward(_user, _amount * 6 / 100, block.timestamp, Express.sameLevel));
            }
        }
    }

    function lookFor(address _user) public view returns (address) {
        if(isVips[_user]) return findVip(inviter[_user], maxLooked); 
        return findVip(_user, maxLooked); 
    }

    function findVip(address _user, uint8 maxDepth) private view returns (address) {
        if (maxDepth == 0 || _user == address(0) || isVips[_user]) {
            return _user;
        }
        address invAddr = inviter[_user];
        return findVip(invAddr, maxDepth - 1);
    }

    function claim(address _user,uint256 _amount) external{
        require(totalTeamReward[_user] >= _amount,"Membership:Invalid claim amount");
        TransferHelper.safeTransfer(token, _user, _amount);
        totalTeamReward[_user] -= _amount;
        claimRecords[_user].push(ClaimRecords(_user,_amount,block.timestamp));
    }
    
    function getUserInfo(address _user) external view returns(User memory){
        return User(isVip[_user],isVips[_user],inviter[_user],invitesNum[_user],totalTeamReward[_user]);
    }

    function getTeamRewardInfo(address _user) external view returns (TeamReward[] memory){
        return teamRewards[_user];
    }

    function getClaimRecordsInfo(address _user) external view returns(ClaimRecords[] memory){
        return claimRecords[_user];
    }

    function updatePercentReceiver(address _twentyPercent,address _tenPercent,address _fourPercent) external onlyOwner{
        fourPercent = _fourPercent;
        twentyPercent = _twentyPercent;
        tenPercent = _tenPercent;
    }

    function updateFixed(uint256 _fixed) external onlyOwner{
        fixedPrice = _fixed;
    }

    function setMaxLooked(uint8 _looked) external onlyOwner{
        maxLooked = _looked;
    }

    function setAdmin(address _admin) external  onlyOwner{
        admin = _admin;
    }

}

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract Currency is ERC20{
//     constructor()ERC20("",""){}
// }

//token:0xA97669a2Bb2Ddcee5F806Dc0C699071cfc309E82
//inviter:0x9828624b952b41f2A5742681E3F4A1A312cb6Dd4

//4:0x9356703BbB5738B0D6f977608e87a556Eb537deD
//10:0x3de09d761BF70F95b29f97f3Dc14386795B6A376
//20:0xB6b25D0972359197864abbAA2328Df80680d9C93

//membership:0xb21d43FA208175233d36212865ddB0611ac8d760
//proxy:0x1C1c80bCA02451fD7026A8B7E904C8140623990b
