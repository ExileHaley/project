#### address
- lp:0x58a8e508E7F1139075616dC2Ff737C2C6C881838(前端不使用)
- yzz:0x2d0Fd45B5D68A1cBDEE6d9c3B0cF7FF2DF01FDDc(前端不使用)

- usdt:0x55d398326f99059fF775485246999027B3197955
- membership:0x44df0800a6d0fA4b5Ad207B34Ba7050aF5E287Fe
- 复制json文件的地址:0xc2d12eA250f4fF972D19Ab0641Bbf5eDFb4340d3



#### membership contract func list
```solidity


    enum Target{
        DAILYINVITE,//0，日邀请标识
        WEEKLYINVITE,//1，周邀请标识
        WEEKLYREMOVE,//2，早鸟奖标识
        LUCKYREWARD,//3，幸运奖标识
        HIERARCHY, //4，层级奖励
        RECOMMEND //5，直退奖励信息
    }

    struct Record{
        Target  target; //Target
        address member; //被邀请地址
        uint256 amount; //奖励的数量，如target = 0，amount = 100e18，意思就是当天直退奖励给当前用户分了100个
        uint256 time;//时间戳
    }


    struct Whole{
        Target  target; //Target
        uint256 amountRewrad; //奖池数量lp
        uint256 members; //参与用户总量
        uint256 countTime; //倒计时
    }


- 邀请用户，_inviter邀请地址，_member当前用户
1. function invite(address _inviter, address _member) external;

- 将用户参与数量amount传入，判断是否符合规则
2. function getAccessAmount(uint256 amount) public view returns(bool supp);

- 用户质押，member当前用户，amount要质押的usdt数量，member邀请人不能为空,否则报错
3. function provide(address member, uint256 amount) external;

- 用户提现，member当前用户，amount要提取的lp数量
4. function withdraw(address member,uint256 amount) external;

- 移除流动性，member当前用户，amount要移除流动性的数量
5. function removeLuidity(address member, uint256 amount) external;

_dailyInvite当前用户当日邀请业绩，_weeklyRemove当前用户通过dapp移除流动性的一周总数量lp。
- _subordinates当前用户邀请的用户列表，_weeklyInvite当周的邀请总业绩，_inviteForm当前用户直接推荐的地址列表，_inviteNum直接推荐的总人数
- _records获取用户奖励记录，奖励记录结构是Record，从这个字段过滤直退等数据
6. function getUserInfo(address member) external view returns(
        uint256 _dailyInvite, 
        uint256 _weeklyRemove,
        uint256 _weeklyInvite,
        address[] memory _inviteForms,
        address[] memory _subordinates,
        Record[] memory _records
    )
- 获取个人信息,_inviter当前用户邀请人地址，_additionalInviter当前用户的直荐地址，_staking当前用户质押的usdt数量，
- _property当前用户拥有的lp token总数量
7. function getBaseUserInfo(address member) external view returns(address _inviter,address _additionalInvi, uint256 _staking, uint256 _property)


- 返回幸运奖信息，lucky是截止目前最后参与的30个人的地址，lastTime最后一个人的参与时间,count倒计时
8. function getLuckyRankings() external view returns(address[] memory lucky, uint256 lastTime,uint256 count);

- 计算当前合约准入数量，返回100e18/200e18/300e18以及0。
- 用户信息的staking字段质押了100e18,那么此时返回100e18，用户可以质押的数量就是0，如果返回300e18，那么用户可以质押的数量就是300 - 100e18；
- 返回0则代表数量没有限制，但要求输入的数量能被100e18整除，此时不考虑用户信息中的staking字段。
9. function getAccessAmountIn() public pure returns(uint256 amountIn);

- 层级溢出 + 移除溢出 + 烧伤溢出 = surplus
10. function surplus() external view returns(uint256);

- 获取首码地址
11. function leader() external view returns(address);

- 返回Whole结构体数组
12. function getWholeInfo() external view returns(Whole[] memory wholes)

- 计算lp的价值是多少u，amount输入lp的数量，会返回价值多少u
13. function getLuidityPrice(uint256 amount) external view returns(uint256)
```


#### 前端更新
- 新增lp价格计算方法
