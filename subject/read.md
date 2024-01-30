#### 测试私募:0x962c527a9Dc33fD010B617b6544aA5a1a5E59428(json也在这里复制)
#### 测试token(前端不使用):0x417328A0c68Fc43c65ed15de5418FC9525837542

#### 正式subject:0x77E34975aBF6432Ed2029Cf7ea571C6ad678cF4F
#### 正式私募:0xCE3e8684B1E10B347922375Bb498785fdEBebC1d

```solidity

- 获取当前用户剩余额度，3个bnb封顶，0.1个bnb起步，所以计算用户剩余额度
1. function getMaximum(address _user) external view returns(uint256)

- 获取用户信息,staking用户参与bnb数量，acquire用户获得subject数量(用户可提现subject数量)
2. function userInfo(address _user) external view returns(uint256 staking, uint256 acquire);

- 用户使用bnb参与私募，_user用户地址，_amount参与的bnb数量，注意payable，这里支付的是bnb
3. function provide(address _user, uint256 _amount) external payable;

- 用户提现subject token
4. function withdraw(address _user, uint256 amount) external;

- 获取倒计时
5. function getCount() external view returns(uint256 count);

struct Record{
        address member; //参与地址
        uint256 amount; //参与数量
        uint256 time; //参与时间
}

- 获取最新的200个用户参与记录
6. function getRecords() external view returns (Record[] memory)

```
