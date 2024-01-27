#### address
- lp:0x812E9f0E36F4661742E1Ed44Ad27F597953eda8f
- yzz:0xA3674C9dcaC4909961DF82ecE70fe81aCfCC6F3c
- usdt:0x55d398326f99059fF775485246999027B3197955
- membership:0x7370A9A6d256a7cf3f93BD91d99bDA87db045B41

- 复制json文件的地址:0xcFf27d11964Df7F912A09D5c46bb21Da5A2f2cFF

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

- 计算当前合约准入数量，返回100e18/200e18/300e18以及0，0则代表数量没有限制，但要求输入的数量能被100e18整除。
9. function getAccessAmountIn() public pure returns(uint256 amountIn);

- 层级溢出 + 移除溢出 + 烧伤溢出 = surplus
10. function surplus() external view returns(uint256);

- 获取首码地址
11. function leader() external view returns(address);

- 返回Whole结构体数组
12. function getWholeInfo() external view returns(Whole[] memory wholes)

```


#### 前端更新
- 重新复制一下json文件
- userinfo更新为getBaseUserInfo方法

#### 合约更新内容
- getUserInfo新增获取用户奖励记录的字段；
- 奖池百分比由固定值修改为可配置；
- 新增部分内容并未部署到链上
