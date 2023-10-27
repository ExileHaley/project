# 🥞 Pancake Frontend

[![Netlify Status](https://api.netlify.com/api/v1/badges/7bebf1a3-be7b-4165-afd1-446256acd5e3/deploy-status)](https://app.netlify.com/sites/pancake-prod/deploys)

This project contains the main features of the pancake application.

If you want to contribute, please refer to the [contributing guidelines](./CONTRIBUTING.md) of this project.

## Documentation

- [Info](doc/Info.md)
- [Cypress tests](doc/Cypress.md)



### src/utils
- farmHelpers.ts 与farm pid相关
- farmPriceHelpers.ts 通过busd和bnb进行基准进行价格计算
- getLpAddress.ts 获取流动性token合约地址
- getRpcUrl.ts 获取不同环境的节点配置
- Multicall.ts 两个版本V1和V2，所有合约调用都通过两个版本的multicall进行合约调用，这里要组装参数；

### src/utils
- farms.ts 这里做合约方法的调用，包括质押、赎回以及提取收益；

### src/state
- Types.ts 主要用于参数的序列化和反序列化，call合约前进行序列化，对返回结果进行反序列化；

### src/state/farms(重点)
- fetchFarmsPrices.ts
- fetchFarmUser.ts 从masterChef合约中获取用户质押信息
- fetchPublicFarmData.ts 使用Pid等从masterChef合约中获取farm池的配置信息
- hooks.ts
- Index.ts

### src/hooks
- useBUSDPrice.ts 通过busd和wbnb计算代币价格
- useContract.ts 这里主要是通过地址和abi生成可写入合约的signer

### src/config
- Index.ts 配置基础信息，这里要做一些修改，比如每个区块产出的cake数量等；
- constants/contracts.ts 主网测试网对应合约的地址配置
- farmAuctions.ts 定义的是跟lp farm ico相关的部分；
- farms.ts 已经存在的farm池；
- tokens.ts 其中cake代币的信息要进行修改；
- Types.ts 定义了序列化和反序列化接口；
