### 接口列表如下：
```golang

请求方式：POST
http://localhost:8080/getRecords


传参方式：
{
    "perPage": 20, //分页，每页请求的数据条数
    "offset":0 //偏移量，从什么位置开始查询
}

返回值：
{
    "code": 0, //请求状态码，0成功，1失败
    "data": [
        {
            "Id": 3, //不展示
            "Token0": "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", //wbnb，直接展示地址
            "Token1": "0xfC8774321Ee4586aF183bAca95A8793530056353", //long，直接展示地址
            "Pair": "0xe958b7BaC028f4B22deD5B3c97B5382894A9503B", //lp token地址，就是wbnb和long组成的池子生成的lp token合约地址，直接展示地址
            "Index": "3", //该索引用于在合约中进行查询比对
            "Amount": "12250706616223682"  //持有的lp token数量，有精度18
        },
        {
            "Id": 14,
            "Token0": "0x7d8B9dca9F312ACE9DBe0D82511336e9cb656E73",
            "Token1": "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
            "Pair": "0xb68DE3CDdC73d1bd3DF1237d84857FAe22869d05",
            "Index": "14",
            "Amount": "57490290746753"
        }
    ],
    "msg": "success"
}

```
```golang

请求方式：GET
http://localhost:8080/totalPairs

返回值：
{
    "code": 0, //状态码
    "data": 28, //目前swap中有28个交易对
    "msg": "success"
}

```

