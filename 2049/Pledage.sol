// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PledageStor{
    address public admin;
    address public implementation;
}

contract Proxy is PledageStor{
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

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
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

//团队总算力（20代）、团队总人数
//团队算力记录、
//团队收益（2代）及算力
//
contract PledageStorV1 is PledageStor{

    struct Team{
        uint256 members;
        uint256 teamTotalStaking;
        uint256 directTotalStaking;
        address[] referrals;
    }
    
    struct User{
        address referrer; 
        uint256 stakedAmount; 
        uint256 earnings; 
        uint256 debt; 
        uint256 createTime;
    }

    struct Records{
        address member;
        uint256 amount;
        uint256 hierarchy;
        uint256 time;
    }

    mapping(address => User) public userInfo;
    mapping(address => Team) public teamInfo;
    mapping(address => bool) public hasReferrals;
    mapping(address => Records[]) public referralRecords;

    address public initialReferrals;
    address public uniswapV2Factory;
    address public uniswaV2Router;
    address public usdt;
    address public token;
    uint256 public totalStaked;
    uint256 public perStakingReward;
    uint256 public period;
    uint256 public interestRates;
    uint256 public decimals;
    
}


contract Pledage is PledageStorV1{

    constructor() {
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "Only the owner can call this function");
        _;
    }

    function initialize() external onlyOwner(){
        
    }

    function updateFarm() external onlyOwner(){
        uint256 tokenAmount = IERC20(token).balanceOf(address(this));
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, token, usdt);
        uint256 amountOut = UniswapV2Library.getAmountOut(tokenAmount, reserveIn, reserveOut);

        address weth = IUniswapV2Router(uniswaV2Router).WETH();
        (uint reserveIn0, uint reserveOut0) = UniswapV2Library.getReserves(uniswapV2Factory, usdt, weth);
        uint256 totalWeth = UniswapV2Library.getAmountOut(amountOut, reserveIn0, reserveOut0);
        perStakingReward = perStakingReward + totalWeth * decimals / totalStaked;
    }

    function registerWithReferrer(address referrerAddress) external {
        require(!hasReferrals[msg.sender], "You already have a referrer");
        require(msg.sender != referrerAddress, "You cannot refer yourself");

        if (referrerAddress != initialReferrals) {
            require(userInfo[referrerAddress].stakedAmount > 0, "Referrer must have a stake");
        }
        userInfo[msg.sender].referrer = referrerAddress;
        hasReferrals[msg.sender] = true;
        // userInfo[referrerAddress].referrals.push(msg.sender);
    }

    function calculateAcrossReferralStakedAmount(address _user) public view returns (uint256 directReferralStaking) {
        address[] memory _referrals = teamInfo[_user].referrals;
        for (uint256 i = 0; i < _referrals.length; i++) {
            directReferralStaking += teamInfo[_referrals[i]].directTotalStaking;
        }
    }

    function provide(address _user,uint256 _amount) external{
        User storage user = userInfo[_user];
        require(user.referrer != address(0),"Pledage:User must bind an inviter");
        user.debt = user.debt + (_amount * perStakingReward);
        if(user.createTime == 0) user.createTime = block.timestamp;
        user.stakedAmount += _amount;
    }


    function stakingLoop(address _user,uint256 _amount)internal{
        
        address currentReferrer = userInfo[_user].referrer;
        for (uint256 i = 0; i < 50; i++) {
            // For the first iteration, update directTotalStaking and add a record
            if(i == 0){
                teamInfo[currentReferrer].directTotalStaking += _amount;
            }
            // Update the referrer's team information
            teamInfo[currentReferrer].teamTotalStaking += _amount;

            // Create a new record for the referrer
                Records memory record = Records({
                    member: _user,
                    amount: _amount,
                    hierarchy: i,
                    time: block.timestamp
                });

            // Push the record into referralRecords
            referralRecords[currentReferrer].push(record);

            // Move to the next referrer in the hierarchy
            currentReferrer = userInfo[currentReferrer].referrer;

            // Check if the next referrer is address(0) and exit the loop if true
            if (currentReferrer == address(0)) {
                break;
            }
        }
    }



}