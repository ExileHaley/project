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
        0xb5f106453e92c83f8ef471e09a8097b99888030beb671302e7c318e4d198c6e3;

    struct Content {
        address token;
        address holder;
        uint256 amount;
        uint256 orderId;
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
                    content.token,
                    content.holder,
                    content.amount,
                    content.orderId
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
        zero,
        one,
        three,
        six,
        year
    } 

    struct User{
        uint256[] amounts;
        uint256[] times;
        Expiration[] expirations;
    } 

    mapping(address => User) userInfo;

    struct Option{
        uint256 optionId;
        address holder;
        address token;
        uint256 amount;
    }

    mapping(uint256 => Option) public optionInfo;

    address token;
    address permit;
    address dead;
    address usdt;
    address uniswapV2Router;
    address uniswapV2Factory;
    bytes32 public DOMAIN_SEPARATOR;

}

contract Pledage is PledageStorV1{

    event Provide(address owner, uint256 amount, uint256 time, Expiration expiration);
    event Withdraw(uint256 orderId, address receiver, address token, uint256 amount,uint256 time);
    constructor(){
        admin = msg.sender;
    }

    receive()external payable{}

    modifier onlyOwner() {
        require(admin == msg.sender,"Caller is not owner");
        _;
    }

    function initialize( address _permit) external onlyOwner(){
        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        dead = 0x000000000000000000000000000000000000dEaD;
        token = 0x33E0B24aaeA62500ca79D33e26EFe576BBf5baCF;
        permit = _permit;
        _updateDomainSeparator();    
    }

    function provide(uint256 _amount,Expiration _expiration) external{
        require(_amount > 0,"Pledage:Invalid provide amount");
        require(_expiration != Expiration.zero,"Pledage:Invalid provide expiration");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), _amount);
        User storage user = userInfo[msg.sender];
        user.amounts.push(_amount);
        user.expirations.push(_expiration);
        user.times.push(block.timestamp);
        emit Provide(msg.sender, _amount, block.timestamp, _expiration);
    }

    function withdraw(SignatureInfo.Content calldata content) external {
        require(getResult(content),"Pledage:Invalid withdraw data");
        require(content.holder != address(0),"Pledage:Invalid withdraw address");
        require(content.amount > 0,"Pledage:Invalid withdraw amount");
        Option storage option = optionInfo[content.orderId];
        option.amount += content.amount;
        option.token = content.token;
        option.holder = content.holder;
        if(option.token != address(0)){
            TransferHelper.safeTransfer(token, content.holder, content.amount * 99 / 100);
            TransferHelper.safeTransfer(token, content.holder, content.amount * 1 / 100);
        }else{
            TransferHelper.safeTransferETH(content.holder, content.amount);
        }

        emit Withdraw(content.orderId, content.holder, content.token, content.amount,block.timestamp);
    }

    function getResult(SignatureInfo.Content calldata content) public view returns(bool){
        return SignatureChecker.verify(SignatureInfo.getContentHash(content), permit, content.v, content.r, content.s, DOMAIN_SEPARATOR);
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

    function getBnbPrice() external view returns(uint256){
        address weth = IUniswapV2Router(uniswapV2Router).WETH();
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, weth, usdt);
        return UniswapV2Library.getAmountOut(1e18, reserveIn, reserveOut);
    }

    function getTokenPrice() external view returns(uint256){
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(uniswapV2Factory, token, usdt);
        return UniswapV2Library.getAmountOut(1e18, reserveIn, reserveOut);
    }

    function emergencyBNB(address receiver,uint256 amount) external onlyOwner(){
        TransferHelper.safeTransferETH(receiver, amount);
    }

    function emergencyToken(address receiver,uint256 amount) external onlyOwner(){
        TransferHelper.safeTransfer(token, receiver, amount);
    }

    function setAdmin(address _admin) external onlyOwner(){
        admin = _admin;
    }

    function setPermit(address _permit) external onlyOwner(){
        permit = _permit;
    }

    function getHash() external pure returns (bytes32){
        return keccak256("Content(address token,address holder,uint256 amount,uint256 orderId)");
    }
}

//logic:0x7952d6E45878Fa7f556455CaEd82663F2D992764
//proxy:0x8C604c522A93fcaa86Dcf093F55236EFb1c2FE7A
