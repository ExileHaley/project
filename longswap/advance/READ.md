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

```