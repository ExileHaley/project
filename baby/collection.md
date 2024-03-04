### 修改内容
- 更新json，有新增方法getCollectInfo
### collection(合约地址):0x9e7C4B4f3cC97Dff91A842E5a478336306206064
### 复制json的地址:0x26AdFBdef9C883C7C50915CBE89AcF388fcE3044


#### func list
```solidity
- 获取用户剩余的私募额度(bnb)
function getQuota(address member) public view returns(uint256);
- 参与私募，用户支付的是bnb，也就是主网币,要求数量大于0.1bnb，但小于上述函数的返回值
function provide(uint256 amount) external payable;

struct Record{              //参与私募的记录
        uint256 amountBNB; //参与私募的数量
        uint256 time;      //参与私募的时间
}
- 获取用户信息，_bnb代表当前用户参与私募的总bnb数量，_token当前用户参与私募后获得的总代币数量，_records记录数组，字段函数见结构体
function getUserInfo(address member) external view returns(uint256 _bnb, uint256 _token, Record[] memory _records);
- 用户提取私募所获的代币
function claim(uint256 amount) external;
- 判断当前系统是否开放了私募代币提现，true表示开放了提现，false表示未开放提现。
function withSwitch() external view returns(bool);
- _bnb当前参与私募的bnb总量，_token代表已经被私募掉的代币数量
function getCollectInfo() external view returns(uint256 _bnb,uint256 _token);
```
