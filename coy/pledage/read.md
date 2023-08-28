#### 合约地址：0x8C5dDb0006cFa9C4478f65D9e1ccD24c3843bCbC
#### wcore地址：0x40375C92d9FAf44d2f9db9Bd9ba41a3317a2404f
#### coy地址：0xf49e283b645790591aa51f4f6DAB9f0B069e8CdD

### 方法列表
```javascript

1. 绑定邀请人地址，_inviter邀请人地址
function bind(address _inviter) external;

2. 通过输入core数量获取同时需要质押的COY数量，amountIn => core数量 / token0 => wcore地址 / token1 => coy地址，
   通过输入coy数量获取同时需要质押的core数量，amountIn => coy数量 / token0 => coy地址 / token1 => wcore地址，
   传入的amountIn如果有精度，返回的数量也会包含精度
function getAmountOut(uint256 amountIn,address token0,address token1) public view returns(uint256 amountOut);


3. 质押，customer是当前用户地址，msg.value要求传入core数量(注意有payable标识)，所以这里需要coy授权，主币core不授权，
   当前函数会通过上述方法进行两者价值相等校验
function provide(address customer) external payable;


    struct User{
        uint256 computility;  //用户算力，有18位精度
        uint256 extractedCore; //用户通过挖矿已经提取的coy值多少core
        uint256 rewardDebt; //这个忽略
        uint256 award; //这是用户通过邀请获得的coy数量
    }

    struct Info{
        User    user; //上述User结构体
        address inv; //当前用户的邀请人地址
        uint256 income; //用户挖矿收益，也就是收益可提现的coy数量
    }



4. 获取用户详细信息，返回值跟上述结构体对应
function getUserInfo(address customer) external view returns(Info memory);

5. 用户提取挖矿收益，customer是当前用户地址，amount是coy数量
function claim(address customer,uint256 amount) external;


6. 用户提取邀请奖励coy，customer是当前用户地址，amount是coy数量
function claimAward(address customer, uint256 amount) external;

    struct Team{
        address recommend; //团队新参与的用户地址
        uint256 amount; //该用户提供的奖励数量coy，有精度
        uint256 createTime; //时间戳，自己转一下
    }
7. 获取当前用户的团队奖励，数据结构如上所示，返回是一个数组，其中的每一个元素都是一个Team
function getUserOfTeamInfo(address customer) external view returns(Team[] memory)
```