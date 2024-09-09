### install foundry-rs/forge-std
```shell
$ forge install foundry-rs/forge-std --no-commit
```
### install openzeppelin-contracts
```shell
$ forge install openzeppelin/openzeppelin-contracts --no-commit
```
### install openzeppelin-contracts-upgradeable
```shell
$ forge install openzeppelin/openzeppelin-contracts-upgradeable --no-commit
```

### deploy
```shell
$ forge script script/LiquidityScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```


### contractAddress:0x44450A202db97dC3F42a21ab4220e8BE9fe0e3bf
### abi: ./out/liquidity.sol/liquidity.json
### func list
```solidity
//用户授权的时候。snake和usdt都要给contractAddress授权，判断getQuoteAmount的usdt数量以及输入sanke数量是否小于授权数量
struct Record{
    address members; //用户钱包地址
    uint256 amountToken; //用户添加的snake数量
    uint256 amountUsdt; //用户添加的usdt数量
    uint256 liquidity; //用户添加后swap生成的流动性代币数量
    uint256 time; //用户添加流动性的时间
}

//提取收益
function claim() external;
//质押数量，这里需要snake和usdt，但是amountToken是snake的数量，不提供usdt的数量
function provide(uint256 amountToken) external;
//获取用户信息
function getUserInfo(address member) external view 
    returns(
        address   inviter, //当前钱包地址的邀请人地址
        uint256   staking, //用户质押的lp数量
        uint256   value,   //用户质押的lp价值多少u
        uint256   dynamic, //用户通过邀请获得的动态算力
        uint256   extracted, //用户已经提取的u/子币数量，因为u和子币是1:1的
        address[] memory members, //当前用户邀请的成员有哪些
        Record[]  memory records //当前用户邀请的成员质押记录
    );
//获取用户的当前收益子币名称
function getUserIncome(address member) public view returns(uint256);
//amountToken这里传入snake的数量，就会算出来usdt的数量，这需要用户钱包里有这么多usdt，展示给用户，根provide差不多
function getQuoteAmount(address amountToken) public view returns(uint256 amountUsdt);
//邀请地址_inviter
function invite(address _inviter) external;
//获取首码地址
function prefixCode() external view returns(address);
```
