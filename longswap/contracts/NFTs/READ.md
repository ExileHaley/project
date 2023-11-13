### NFT合约地址:0x1c78d66577894e84502A1a87E3B5Ccc30DB44C04
### market合约地址:0xa2917088CE71cCc8b8C78F1DF00d9bd3b9477B56
### baseURI:https://nftstorage.link/ipfs/bafybeidhaakzu247fujl2kkpilaczc7hu3gbadrb67uxujwp2vovqu7nde/

#### NFT方法
```javascript
//判断是否授权，owner是当前用户钱包地址，operator是market合约地址，返回值true表示已经授权，false表示未授权，通过下面的方法让用户授权
function isApprovedForAll(address owner, address operator) public view virtual returns (bool)
//授权，operator是market的地址，approved是true表示用户授权给market合约，才能挂单
function setApprovalForAll(address operator, bool approved) public
//传入用户地址，查询当前用户持有的所有NFT的tokenId
function getUserHoldInfo(address user) external view returns(uint256[] memory)
```

#### market方法
```javascript

    enum State{
        sold, //出售完成
        sellIn, //出售中
        cancelled // 已取消
    }

    struct Option{
        uint256 optionId; //订单编号
        address holder; //订单持有者地址
        uint256 tokenId; //订单中NFT的tokenId
        address payment; //支持付款的币种合约地址，long/lt
        uint256 price; //当前订单总价
        State   state; //状态
    }

    struct Record{
        uint256 optionId; //订单编号
        address payment; //支付的币种合约地址
        uint256 income; //收益数量
        uint256 time; //出售时间
    }

//创建订单，payment是long或LT的地址，由用户选择，price是要卖多少
function createOption(uint256 tokenId, address payment,uint256 price) external
//购买订单，参数是订单编号
function purchaseOption(uint256 optionId) external
//取消订单，参数是订单编号
function cancelOption(uint256 optionId) external 
//获取市场中所有正在出售的(有效)的订单信息
function getOptions() external view returns(Option[] memory)
//获取用户挂售的所有订单
function getUserOptions(address user) external view returns(Option[] memory)
//获取用户出售NFT获得token的记录
function getUserIncomeRecords(address user) external view returns(Record[] memory)

```
