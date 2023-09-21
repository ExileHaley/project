##### 2049:0x33e0b24aaea62500ca79d33e26efe576bbf5bacf
##### logic:0xb9B5dDF6523d15159959e4e6132A44F158b5FBbE
##### proxy:0xA953718A2F2a41f6507D17DDF50713351d414479
##### contentHash:0xb5f106453e92c83f8ef471e09a8097b99888030beb671302e7c318e4d198c6e3
##### domain:


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
