#### 私募:0xa5F55ac7D5d5a37b3CB3F9194958cF555bF04C39



```solidity

- 获取当前用户剩余额度，3个bnb封顶，0.1个bnb起步，所以计算用户剩余额度
1. function getMaximum(address _user) external view returns(uint256)
- 获取用户信息,staking用户参与bnb数量，acquire用户获得subject数量(用户可提现subject数量)
2. function userInfo(address _user) external view returns(uint256 staking, uint256 acquire);
- 用户使用bnb参与私募，_user用户地址，_amount参与的bnb数量，注意payable，这里支付的是bnb
3. function provide(address _user, uint256 _amount) external payable;
- 用户提现subject token
4. function withdraw(address _user, uint256 amount) external;
- 是否已经开放了提现,true代表已经开放了subject提现，false则代表没有
5. function withdrawSwitch()external view returns(bool);

```