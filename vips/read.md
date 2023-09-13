

#### deep address:0xA97669a2Bb2Ddcee5F806Dc0C699071cfc309E82
#### vips 合约地址:0x798D0f103971bAE08B6Ca5aA41E88e58FC1FcCe9
#### 初始邀请地址:0x9828624b952b41f2A5742681E3F4A1A312cb6Dd4
#### vips abi:同级目录下membership.json

#### vip合约方法列表:

``` javascript
1. 绑定推荐人，_inviter推荐人地址
function bind(address _inviter) external;

2. 获取购买节点需要支付的deep数量
function getAmountOut() public view returns(uint256 amountOut)

3. 购买节点，deep数量合约回自己从用户钱包里扣，所以deep需要对合约进行授权
function purchasingVip(address _user) external;

4. 提取团队推荐收益
function claim(address _user,uint256 _amount) external;

    struct User{
        bool isp; //是不是vip，当前地址如果购买了节点就是true，否则false。
        bool isps; //是不是vips，推荐超过2个人购买节点就是vips，true表示已经达成，false表示未达成。
        address inv; //邀请人地址
        uint256 invNum; //当前地址总共直推的用户数量
        uint256 totalTR; //当前用户总的团队奖励(deep)，用户只有这一个收益可以提取，对应到上面的claim方法
    }
5. 获取用户信息详情，返回数据如上述User结构
function getUserInfo(address _user) external view returns(User memory);

    enum Express{direct,vips,sameLevel}
    //`Team info list`
    struct TeamReward{
        address partner; //被邀请地址
        uint256 rewardValue; //奖励数量
        uint256 rewardTime; //奖励时间
        Express express; //0代表直推奖励，1代表vips奖励，2代表同级奖励
    }
6. 获取用户的团队奖励详情，返回数据如上述TeamReward结构
function getUserTeamInfo(address _user) external view returns(TeamReward[] memory);
7. 获取用户的收益提现记录，返回的是ClaimRecords[]这样一个结构体数组

    struct ClaimRecords{
        address receiver; //提现收益到的地址
        uint256 amount; //提现的数量
        uint256 claimTime; //提现的时间
    }
function getClaimRecordsInfo(address _user) external view returns(ClaimRecords[] memory)
```
