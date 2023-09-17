### 2049:0x33e0b24aaea62500ca79d33e26efe576bbf5bacf
### pledage:0x2e9f5bF02e70aa84CDAF6F16a1b360607d5B59e5
### 初始邀请人:0x6cBc50EE3cb957B5aD14dD1B4833B86296e77122


### 方法列表：
```
1.绑定邀请人地址，邀请人地址
function registerWithReferrer(address referrerAddress) external

enum Expiration{
        one, //1个月
        three, //3个月
        six, //6个月
        year //1年
    } 

2.参与质押，_amount数量，expiration期限
function provide(uint256 _amount, Expiration expiration) external

3.赎回质押，根据订单号optionId赎回对应订单的质押数量
function withdraw(uint256 optionId) external


enum Expiration{
        one, //1个月
        three, //3个月
        six, //6个月
        year //1年
    } 
 struct Option{
        uint256     optionId; //订单编号
        address     owner; //订单拥有者
        uint256     amount; //订单质押的数量
        uint256     createTime; //订单创建时间
        uint256     extractedBNB; //已经提取的bnb数量
        bool        isUnstaking; //是否赎回
        Expiration  expiration; //质押期限
    } 

struct Info{
        Option option; //上述订单信息
        uint256 income; //当前订单的可提取收益
    }

4.获取用户所有的订单信息
function getUserOptions(address _user) external view returns(Info[] memory)

5.用户提取质押的静态收益
function claim(uint256 optionId,uint256 amountBNB) external

struct Content {
        address holder; //奖励接收者地址
        uint128 amount; //提取的动态收益数量
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
    }

6.用户提取团队奖励收益
function claimWithPermit(SignatureInfo.Content calldata content) external
```