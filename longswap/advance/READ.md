
### 前端对接如下
### pledage:0x89c2C532C2670036A6862d27109fF3c25Cd250Fb
### 复制json:0x31e0B55C1123FD20739058e9802bDB4ce6c86213

```solidity
- 获取用户收益bebe的数量
function getUserIncome(address _user) public view returns(uint256 _income);
- 用户提取收益
function claim(address _user,uint256 _amount) external;
- amount返回的是long销毁的数量，其余两个不用展示
function userInfo(address member) external view returns(uint256 amount,uint256 stakingTime,uint256 income); 
```
