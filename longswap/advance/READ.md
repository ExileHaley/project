### pledage contract:0x7eA65FcefFED446F452799d93654A921B8905D02
### long token:0xfc8774321ee4586af183baca95a8793530056353
### initialInviter:0x7E0134FE4992D9A3ad519164C5AFF691112b7bd2

### functions
```javascript

1.绑定邀请关系，参数为邀请人地址
function bind(address _inviter) external
2.质押long token，不需要参数
function provide() external
3.获取用户释放的lt数量
function getUserIncome(address _user) public view returns(uint256 _income)
4.lt提现，_user用户地址，_amount要提现的数量，数量根据上述getUserIncome获取
function withdraw(address _user,uint256 _amount) external
5.获取当前用户的邀请记录
struct Record{
        address beInvited;
        uint256 time;
}
//返回结果是热records数组
function getUserInviteRecords(address _user) external view returns (Record[] memory)
6.获取用户详情
struct User{
        bool    whetherStaking; //是否参与质押
        uint256 stakingTime; //质押时间，这个可以不展示
        uint256 inviterNum; //邀请人数
        address inviter; //当前地址的推荐人地址
        uint256 income; //这个忽略
    }
//返回结果是上述结构体
function userInfo(address _user)external view returns(User memory)

```