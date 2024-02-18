### baby token(代币):
### skaing(质押):
### 复制json:

```solidity
- _inviter邀请人地址
function invite(address _inviter) external;
- 质押，_amount要质押的数量，要求大于1小于200个
function provide(uint256 _amount) external;
- 赎回质押的baby，默认赎回全部
function withdraw() external;
- 提取收益，默认提取全部
function claim() external;

    enum Mark{
        INVAILD, //无效
        ONE, //直退
        TWO, //二代
        THREE //三代
    }

    enum Operate{
        Increase, //质押
        reduce //赎回
    }

    struct Record{
        Operate operate;
        Mark    mark;
        address members; //用户地址
        uint256 amount; //质押或赎回数量
        uint256 time; //质押或赎回事件
    }

- 获取用户信息,_inviter当前用户推荐人地址，_staking当前用户的质押数量，_dynamic当前用户的动态算力，_income当前用户的收益(BNB)
- _members当前用户推荐其他地址列表，_records下属用户的质押赎回记录
function getUserInfo(address member) external view returns(
        address _inviter,
        uint256 _staking,
        uint256 _dynamic,
        uint256 _income,
        address[] memory _members,
        Record[]  memory _records
);
```