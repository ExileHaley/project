### YZZ:
### Membership:

### membership func list
//邀请用户，_inviter邀请地址，_member当前用户
1. function invite(address _inviter, address _member) external;

//将用户参与数量amount传入，判断是否符合规则
2. function getAccessAmount(uint256 amount) public view returns(bool supp);

//用户质押，member当前用户，amount要质押的usdt数量，member邀请人不能为空
3. function provide(address member, uint256 amount) external;

//用户提现，member当前用户，amount要提取的lp数量
4. function withdraw(address member,uint256 amount) external;

//移除流动性，member当前用户，amount要移除流动性的数量
5. function removeLuidity(address member, uint256 amount) external;

// 获取个人信息,_inviter当前用户邀请人地址，_additionalInviter当前用户的直荐地址，_staking当前用户质押的usdt数量，
// _property当前用户拥有的lp token总数量，_dailyGrades当前用户当日邀请业绩，_weeklyRemove当前用户通过dapp移除流动性的一周总数量lp。
// _subordinates当前用户邀请的用户列表
6. function getUserInfo(address member) external view returns(
        address _inviter,
        address _additionalInviter,
        uint256 _staking, 
        uint256 _property,
        uint256 _dailyGrades,
        uint256 _weeklyRemove,
        address[] memory _subordinates)

//获取邀请列表或移除流动性列表，target传0代表获取全网当日直推的地址列表，传1代表获取全网一周移除的流动性lp的地址列表。
7. function getRankings(Target target) external view returns(address[] memory)

//返回幸运奖信息，lucky是截止目前最后参与的30个人的地址，lastTime最后一个人的参与时间
8. function getLuckyRankings() external view returns(address[] memory lucky, uint256 lastTime);