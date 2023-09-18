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

library SignatureInfo {
    bytes32 constant CONTENT_HASH =
        0x58e2f0ec35eb789493367bbd774d478d0e7e6916118069574ff2690b38004245;

    struct Content {
        address holder;
        uint128 amount;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
    }

    function getContentHash(Content calldata content)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    CONTENT_HASH,
                    content.holder,
                    content.amount
                )
            );
    }

}

library SignatureChecker {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        return recover(digest, v, r, s) == signer;
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

contract PledageStorV1 is PledageStor{
    enum Expiration{
        one,
        three,
        six,
        year
    }   
    struct Option{
        uint256     optionId;
        address     owner;
        uint256     amount;
        uint256     createTime;
        uint256     extractedBNB;
        bool        isUnstaking;
        Expiration  expiration;
    } 
    mapping(address => uint256[]) optionIds;
    mapping(uint256 => Option) public optionInfo;
    mapping(address => address) public referrer;
    mapping(Expiration => uint256) stakingRate;
    mapping(Expiration => uint256) duration;

    address public initialReferrer;
    address public uniswapV2Factory;
    address public uniswapV2Router;
    address public token;
    address public usdt;
    address public permit;

    uint256 public initialOptionNum;
    uint256 public totalStaking;

    bytes32 public  DOMAIN_SEPARATOR;

}

contract Pledage is PledageStorV1{

    struct Info{
        Option option;
        uint256 income;
    }
    event Register(address registerAddress,address referrerAddress);
    event CreateOption(address owner,uint256 optionId,uint256 amount,uint256 crateTime, Expiration expiration);
    event Withdraw(address owner,uint256 optionId,uint256 amount);
    event ClaimWithPermit(address owner,uint256 amountBNB);

    constructor() {
        admin = msg.sender;
    }
    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == admin, "Pledage:Caller is not owner");
        _;
    }

    function initialize(
        uint256[] calldata rates,uint256[] calldata durations,
        address _initialReferrer,address _token, address _permit
    ) external onlyOwner(){
        //0x10ED43C718714eb63d5aA57B78B54704E256024E
        //0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
      
        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        initialReferrer = _initialReferrer;
        token = _token;
        permit = _permit;
        stakingRate[Expiration.one] = rates[0];
        //todo 目前是测试设置，正式版本部署时要做更新
        duration[Expiration.one] = durations[0] * 30;
        stakingRate[Expiration.three] = rates[1];
        duration[Expiration.three] = durations[1] * 86400;
        stakingRate[Expiration.six] = rates[2];
        duration[Expiration.six] = durations[2] * 86400;
        stakingRate[Expiration.year] = rates[3];
        duration[Expiration.year] = durations[3] * 86400;   
        initialOptionNum = 1;
        _updateDomainSeparator();    
    }

    function calculateIncomeUSDT(uint256 amount) public view returns(uint256){
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, token, usdt);
        return UniswapV2Library.getAmountOut(amount, reserveIn, reserveOut);
    }

    function calculateIncomeBNB(uint256 amount) public view returns(uint256){
        address weth = IUniswapV2Router(uniswapV2Router).WETH();
        (uint reserveIn0, uint reserveOut0) = UniswapV2Library.getReserves(uniswapV2Factory, usdt, weth);
        return UniswapV2Library.getAmountOut(amount, reserveIn0, reserveOut0);
    }

    function registerWithReferrer(address referrerAddress) external {
        require(msg.sender != referrerAddress, "Pledage:You cannot refer yourself");
        require(referrer[msg.sender] == address(0),"Pledage:Invalid referrer address");
        if (referrerAddress != initialReferrer) {
            require(optionIds[referrerAddress].length > 0, "Pledage:Referrer must have a stake");
        }
        referrer[msg.sender] = referrerAddress;
        emit Register(msg.sender, referrerAddress);
    }

    function provide(uint256 _amount, Expiration expiration) external{
        //todo 部署正式合约时做更新，这里需要100e18的限制
        // require(_amount >= 100e18,"Pledage:Invalid provide amount");
        require(referrer[msg.sender] != address(0),"Pledage:Invalid referrer address");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), _amount);
        optionInfo[initialOptionNum] = Option(initialOptionNum,msg.sender,_amount,block.timestamp,0,false,expiration); 
        optionIds[msg.sender].push(initialOptionNum);
        totalStaking += _amount;
        emit CreateOption(msg.sender, initialOptionNum, _amount, block.timestamp, expiration);
        initialOptionNum++;
    }

    function withdraw(uint256 optionId) external{
        Option storage option = optionInfo[optionId];
        require(block.timestamp >= option.createTime + duration[option.expiration],"Pledage:Invalid withdraw operate");
        require(!option.isUnstaking,"Pledage:Invalid option state");
        TransferHelper.safeTransferFrom(token, address(this), option.owner, option.amount * 99 /100);
        totalStaking -= option.amount;
        option.isUnstaking = true;

        emit Withdraw(option.owner, optionId, option.amount);
    }

    function getOptionIncome(uint256 optionId) public view returns(uint256 amountBNB){
        Option storage option = optionInfo[optionId];
        if(block.timestamp >= option.createTime + duration[option.expiration]){
            uint256 tokenValue = option.amount * stakingRate[option.expiration] * duration[option.expiration] / 1000;
            if(calculateIncomeBNB(calculateIncomeUSDT(tokenValue)) >= option.extractedBNB)
                        amountBNB = calculateIncomeBNB(calculateIncomeUSDT(tokenValue)) - option.extractedBNB;
        }else{
            uint256 middleTime = block.timestamp - option.createTime;
            uint256 middleTokenValue = option.amount * stakingRate[option.expiration] * middleTime / 1000;
            if (calculateIncomeBNB(calculateIncomeUSDT(middleTokenValue)) >= option.extractedBNB)
                        amountBNB = calculateIncomeBNB(calculateIncomeUSDT(middleTokenValue)) - option.extractedBNB;
        }
    }

    function getUserOptions(address _user) external view returns(Info[] memory){
        Info[] memory infos = new Info[](optionIds[_user].length);
        for(uint i=0; i<optionIds[_user].length; i++){
            Option memory option = optionInfo[optionIds[_user][i]];
            infos[i] = Info(option,getOptionIncome(optionIds[_user][i]));
        }
        return infos;
    }

    function claim(uint256 optionId,uint256 amountBNB) external{
        Option storage option = optionInfo[optionId];
        uint256 income = getOptionIncome(optionId);
        require(income >= amountBNB,"Pledage:Invalid claim amount");
        TransferHelper.safeTransferETH(msg.sender, amountBNB * 95 / 100);
        option.extractedBNB += amountBNB;
    }


    function claimWithPermit(SignatureInfo.Content calldata content) external{
        require(getResult(content),"Membership:Signture error");
        TransferHelper.safeTransferETH(content.holder, content.amount);
        emit ClaimWithPermit(content.holder, content.amount);
    }

    function getResult(SignatureInfo.Content calldata content) public view returns(bool){
        return SignatureChecker.verify(SignatureInfo.getContentHash(content), permit, content.v, content.r, content.s, DOMAIN_SEPARATOR);
    }


    function emergencyBNB(address receiver,uint256 amount) external onlyOwner(){
        TransferHelper.safeTransferETH(receiver, amount);
    }

    function emergencyToken(address receiver,uint256 amount) external onlyOwner(){
        TransferHelper.safeTransfer(token, receiver, amount);
    }

    function _updateDomainSeparator() private {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Pledage"),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

}

//2049:0x33e0b24aaea62500ca79d33e26efe576bbf5bacf
//initAddress:0x6cBc50EE3cb957B5aD14dD1B4833B86296e77122
//permit:0x7fcc706D37EDcf4EE81375D9FAe233857EEcFd45

//logic:0x2E7EcF8249D6c557463f82B260A2eD130343930E
//proxy:0x2e9f5bF02e70aa84CDAF6F16a1b360607d5B59e5




//000000000000000000