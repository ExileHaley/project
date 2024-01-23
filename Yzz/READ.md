#### address
- lp:0x812E9f0E36F4661742E1Ed44Ad27F597953eda8f
- yzz:0xA3674C9dcaC4909961DF82ecE70fe81aCfCC6F3c
- usdt:0x55d398326f99059fF775485246999027B3197955
- membership:0x6839a000A061bdB10f92F6ca886A133E6cc04da4

- 复制json文件的地址:0x7FAB2fb85EC61a9FBAd1Ca273A6cFAbDB7BbaA72

#### membership contract func list
```solidity

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

- 获取个人信息,_inviter当前用户邀请人地址，_additionalInviter当前用户的直荐地址，_staking当前用户质押的usdt数量，
- _property当前用户拥有的lp token总数量，_dailyInvite当前用户当日邀请业绩，_weeklyRemove当前用户通过dapp移除流动性的一周总数量lp。
- _subordinates当前用户邀请的用户列表，_weeklyInvite当周的邀请总业绩，_inviteForm当前用户直接推荐的地址列表，_inviteNum直接推荐的总人数
6. function getUserInfo(address member) external view returns(
        address _inviter,
        address _additionalInviter,
        uint256 _staking, 
        uint256 _property,
        uint256 _dailyInvite,
        uint256 _weeklyInvite,
        uint256 _weeklyRemove,
        address[] memory _subordinates,
        address[] memory _inviteForms,
        uint256 _inviteNum)

- 获取邀请列表或移除流动性列表，target传0代表获取日排行地址列表，传1代表获取周排行地址列表，传2代表获取早鸟奖地址列表。
7. function getRankings(Target target) external view returns(address[] memory)

- 返回幸运奖信息，lucky是截止目前最后参与的30个人的地址，lastTime最后一个人的参与时间
8. function getLuckyRankings() external view returns(address[] memory lucky, uint256 lastTime);

- targe传0/1/2，分别是获取日排行、周排行、早鸟奖的开奖轮次
9. function round(Target target) public view returns(uint256);

struct Assemble{
        address member; //用户地址
        uint256 amount; //开奖时用户的业绩
}

- 根据上述方法拿到轮次，在当前方法中传入target，以及轮次round，返回历史开奖信息结构体Assemble
10. function history(Target target, uint256 round) public view returns(Assemble[]);

```


#### error
- 新增一个返回支持数量的方法，目前只判断了是否支持