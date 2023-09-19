### 2049:0x33e0b24aaea62500ca79d33e26efe576bbf5bacf
### pledage:0xF12C8F7B800eB9Da1233d2C9555D9fc7Cd0fAb49


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
http://localhost:8080/sign
get 路径传参currency=bnb
http://localhost:8080/getPrice?currency=bnb
http://localhost:8080/getPrice?currency=token

```
