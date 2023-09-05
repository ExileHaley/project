### deep token address:
### vip合约地址:
### vip合约方法列表:

``` javascript
1. 绑定推荐人，_inviter推荐人地址
function bind(address _inviter) external;
2. 获取购买节点需要支付的deep数量,这里amountIn输入500个，token0输入usdt地址，token1输入deep地址
function getAmountOut(uint256 amountIn,address token0,address token1) public view returns(uint256 amountOut)
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
    struct TeamReward{
        address member;//团队新参与的钱包地址
        uint256 amount;//能给到当前地址的奖励
        uint256 time; //发放奖励的时间
    }
6. 获取用户的团队奖励详情，返回数据如上述TeamReward结构
function getUserTeamInfo(address _user) external view returns(TeamReward[] memory);
```
