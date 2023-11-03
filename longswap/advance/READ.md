
### pledage contract:0xfC0475CbF48f4754AC2b3F44CCF3d9F14590913c
### long token:0xfc8774321ee4586af183baca95a8793530056353


### functions
```javascript

1.绑定邀请关系，参数为邀请人地址
function bind(address _inviter) external
2.质押long token，不需要参数,这里有修改，需要传入参数，用户的质押数量，0.1个起步
function provide(uint256 amount) external
3.获取用户释放的lt数量
function getUserIncome(address _user) public view returns(uint256 _income)
4.lt提现，_user用户地址，_amount要提现的数量，数量根据上述getUserIncome获取
function withdraw(address _user,uint256 _amount) external
5.获取当前用户的邀请记录
struct Record{
        address beInvited;
        uint256 time;
}
//返回结果是records数组
function getUserInviteRecords(address _user) external view returns (Record[] memory)
6.获取用户详情
struct User{
        uint256 amount; //质押数量
        uint256 stakingTime; //质押时间，这个可以不展示
        uint256 inviterNum; //邀请人数
        address inviter; //当前地址的推荐人地址
        uint256 income; //这个忽略
    }
//返回结果是上述结构体
function userInfo(address _user)external view returns(User memory)
//判断当前用户是否需要进行映射，true标识需要映射，false则不需要
function getIsMapping(address _user) public view returns(bool isMap)
//执行映射，需要映射
function execute(address _user) external


注：请更新质押合约地址，另外判断如果需要映射，弹窗强行让用户进行映射，映射完成才可以参与其他的

```
