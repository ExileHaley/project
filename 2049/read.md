### 2049:0x33e0b24aaea62500ca79d33e26efe576bbf5bacf
### pledage:0xF12C8F7B800eB9Da1233d2C9555D9fc7Cd0fAb49

##### permit:0xD5b300660126FeFab55BDC869DE8d1e72f37A5Bb
##### logic:0xed27d76BAe9Ba5B4C032F53502D0b9c32FCcD27A
##### proxy:0xBb56fF2225b083f55F5c28f4ac5cC83F11608D95
##### contentHash:0xb5f106453e92c83f8ef471e09a8097b99888030beb671302e7c318e4d198c6e3
##### domain:0x668a33915259cac6b50cec3895318ec125b2ce62e635c3f01cc2cf34ea572564


### 方法列表：
```javascript

enum Expiration{
        zero, //这个不允许传
        one, //30天
        three, //90天
        six, //180天
        year //360天
    } 

1.参与质押，_amount数量，expiration期限
function provide(uint256 _amount, Expiration expiration) external

struct Content {
        address token;
        address holder;
        uint256 amount;
        uint256 orderId;
        uint256 deadline;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
    }
2.提现，参数就是上面这个结构体
function withdraw(SignatureInfo.Content calldata content) external


接口列表：
{
     "token":""
     "holder":""
     "amount":""
     "orderId":""
}
post json传参
{
    "token":"0x33e0b24aaea62500ca79d33e26efe576bbf5bacf",
    "holder":"0x33e0b24aaea62500ca79d33e26efe576bbf5bacf",
    "amount":"100000000000",
    "orderId":"1"
}
http://localhost:8080/sign
get 路径传参currency=bnb
http://localhost:8080/getPrice?currency=bnb
http://localhost:8080/getPrice?currency=token

```
