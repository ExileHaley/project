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
$ forge script script/StakingScriptMainnet.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```

### deploy
```shell
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```

### 代理合约地址:
### 逻辑合约地址:

### func list
```solidity
    //首码地址
    function prefixCode() extternal view returns(address);
    //_inviter邀请人地址
    function invite(address _inviter) external;
    //质押,_amount要大于等于0.1wukong
    function provide(uint256 _amount) external;
    //赎回
    function withdraw() external;
    //提取收益
    function claim() external;

    enum Mark{
        INVAILD,
        ONE,
        TWO
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
    //获取用户收益
    function getUserInfo(address member) external 
            view 
            returns(
            address _inviter, //当前用户的邀请地址
            uint256 _staking, //当前用户质押数量，也就是静态算力
            uint256 _dynamic, //当前用户通过邀请获得的动态算力
            uint256 _income,  //当前用户质押得到的收益
            address[] memory _members, //当前用户邀请了那些人，直推的地址
            Record[]  memory _records  //当前用户推荐的下级以及下下级质押记录，其中mark为1是下级，2是下下级
    );

    function swap(uint256 _amount) external;
```