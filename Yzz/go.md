### 接口请求列表
1. 获取日排名、周排名、早鸟奖的所有参与地址
- 请求方式 GET
- 参数target的值为0/1/2，分别对应日排名、周排名、早鸟奖的地址列表
- url:http://localhost:8080/getRankings?target=0


2. 根据单个地址获取该地址对应的业绩
- 请求方式 POST，如下:
- 参数target的值为0/1/2，分别对应当前地址日排名业绩、周排名业绩、早鸟奖业绩
```json
{
    "target":"0",
    "members":"0x............00001"
}
```
- url:http://localhost:8080/getGrades


3. 上述方法是单个地址获取业绩，当前方法提供批量获取业绩
- 请求方式 POST，如下:
```json
{
        "target":"0",
        "members":["0x............00001","0x............00002"]
}
```
- url:http://localhost:8080/multiGetGrades
- 注：当前方法支持每次300个以下的地址进行调用

4. 分发奖励，链下进行排名后对排名前30个地址进行奖励分发
- 请求方式 POST，如下:
- 参数：members传入地址列表数组，按照从大到小的排列方式将30个地址填入到member字段，target其中0/1/2，代表发放日排名奖、周排名奖、早鸟奖
```json
{       
        "members":["0x7E0134FE4992D9A3ad519164C5AFF691112b7bd2","0x7E0134FE4992D9A3ad519164C5AFF691112b7bd2"],
        "target":"0",
        "mark":"自定义"
}
```
- url:http://localhost:8080/distribute

5. 请求分发奖励的执行结果，根据4方法中的mark字段进行请求，4提交交易后2分钟之后即可以查询
- 请求方式 GET
- 参数：mark是执行分发时提供的标识字段，提交交易时mark不可重复使用
- url:http://localhost:8080/getResult?mark=自定义