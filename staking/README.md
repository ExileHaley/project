### install foundry-rs/forge-std
```shell
$ forge install foundry-rs/forge-std --no-commit
```
### install openzeppelin-contracts
```shell
$ forge install openzeppelin/openzeppelin-contracts --no-commit
```
### install openzeppelin-contracts-upgradeable
```shell
$ forge install openzeppelin/openzeppelin-contracts-upgradeable --no-commit
```

### deploy
```shell
$ forge script script/StakingScriptMainnet.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```

### deploy
```shell
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```

### staking部署地址
- impl:0x56a0A2E82d7dfd651E796FD6D3750b1e166f77e1
- 0x29F152B6881E5f3769972CeedDBC7Ca941947980

### abi文件
- 在当前项目out文件夹下找到Staking.sol文件夹，abi就在其中。

### staking function list
```solidity
    struct NftRecords{
        address purchaser; //购买NFT的地址
        uint256 nftAmount; //购买的NFT数量
        uint256 time;      //购买NFT的时间
    }
    //获取某个地址的邀请记录
    function getNftInviteRecords(address user) external view returns(NftRecords[] memory);
    //获取某个地址有效邀请剩余数量，邀请10张奖励推荐人一张，奖励完1张就会减掉，该值就会减掉10张
    function getInvitePurchaseAmount(address user) external view returns(uint256);
    //获取购买数量对应需要的bnb数量，nfts要购买的nft数量是多少
    function getPurchase(uint256 nfts) public view returns(uint256);
    //获取兑换结果，tokenIds是一个数组，里面传tokenId列表，返回的是这些所有的nft可以兑换多少个子币
    function getSwapResult(uint256[] memory tokenIds) public view returns(uint256);
    //购买nft，amount是要购买的nft数量，所需bnb根据getPurchase方法计算
    function purchase(uint256 amount) external payable;
    //兑换子币，tokenIds是一个tokenId的数组，可以兑换的子币数量根据getSwapResult方法计算
    function swap(uint256[] memory tokenIds) external;
```

### NFT function list
```solidity
    //根据tokenId获取对应的json文件访问路径，json文件中有一个image字段，根据该字段的值拿到图片访问路径
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory);
```