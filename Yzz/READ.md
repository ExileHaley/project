### 前端更新内容备注
- 更新json文件；
- getPrizeInfo()方法返回的数据发生了变化；
- getLuckyRewards..该方法更新为getProsperOrEarlyBirdInfo()；
- 早鸟保卫和繁荣保卫仍旧由合约返回，日/周邀请，周移除走中心化接口；

#### address
- lp:0x58a8e508E7F1139075616dC2Ff737C2C6C881838
- yzz:0x2d0Fd45B5D68A1cBDEE6d9c3B0cF7FF2DF01FDDc(前端不使用)

- usdt:0x55d398326f99059fF775485246999027B3197955

#### 新的测试版本
- membership:0x59dda72C4f1254CC7B860CBd914226dd7cE04847
- 复制json文件的地址:0x1B9C6d9965027a3A0e7323E64f3233c0E1968827


#### membership contract func list
```solidity
    enum Target{
        DAILYINVITE, // 0，日邀请
        WEEKLYINVITE, //1，周邀请
        WEEKLYREMOVE, //2，周移除
        PROSPER,      //3，繁荣保卫
        EARLYBIRD    //4，早鸟保卫
    }

    struct Prize{
        Target target; //奖金类型
        uint256 amount; //奖金数量
    }

- 邀请用户，_inviter邀请地址，_member当前用户
1. function invite(address _inviter, address _member) external;

- 将用户参与数量amount传入，判断是否符合规则
2. function getAccessAmount(uint256 amount) public view returns(bool supp);

- 用户质押，member当前用户，amount要质押的usdt数量，member邀请人不能为空,否则报错
3. function provide(address member, uint256 amount) external;

- 获取首码地址
4. function leader() external view returns(address);

- 移除流动性，member当前用户，amount要移除流动性的数量,这里注意因为lp代币在用户钱包中，要移除lp必须对membership进行授权，否则执行失败
5. function removeLuidity(address member, uint256 amount) external;


_dailyInvite当前用户当日邀请业绩，_weeklyRemove当前用户通过dapp移除流动性的一周总数量lp。
- _subordinates当前用户邀请的用户列表，_weeklyInvite当周的邀请总业绩，_inviteForm当前用户直接推荐的地址列表，_inviteNum直接推荐的总人数
6. function getUserInfo(address member) external view returns(
        uint256 _dailyInvite, 
        uint256 _weeklyRemove,
        uint256 _weeklyInvite,
        address[] memory _inviteForms,
        address[] memory _subordinates
    )
- 获取个人信息,_inviter当前用户邀请人地址，_additionalInviter当前用户的直荐地址，_staking当前用户质押的usdt数量，
- _property当前用户拥有的lp token总数量
7. function getBaseUserInfo(address member) external view returns(address _inviter,address _additionalInvi, uint256 _staking, uint256 _property)


- target传3或4，3返回繁荣保卫最后一个地址和最新时间以及倒计时，4返回早鸟保卫最后一个地址和最新时间以及倒计时
8. function getProsperOrEarlyBirdInfo(Target target) external view returns(address last, uint256 lastTime,uint256 count)；

- 计算当前合约准入数量，返回100e18/200e18/300e18以及0。注意看描述
- 用户信息的staking字段质押了100e18,那么此时返回100e18，用户可以质押的数量就是0，如果返回300e18，那么用户可以质押的数量就是300 - 100e18；
- 返回0则代表数量没有限制，但要求输入的数量能被100e18整除，此时不考虑用户信息中的staking字段。
9. function getAccessAmountIn() public pure returns(uint256 amountIn);

- 计算lp的价值是多少u，amount输入lp的数量，会返回价值多少u
10. function getLuidityPrice(uint256 amount) external view returns(uint256)

- 获取各个奖池的大小，返回结构体Prize数组
11. function getPrizeInfo() public view returns(Prize[] memory);

- 整个系统中今日溢出总量,日排行+周排行+周移除+幸运奖+未分的部分
function totalSurplus() external view returns(uint256);

```

