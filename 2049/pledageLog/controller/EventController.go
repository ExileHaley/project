package controller

import (
	"context"
	"fmt"
	"math/big"
	"os"
	"pledageLog/dao"
	"strconv"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

type EventController struct {
	client             *ethclient.Client
	contractABI        abi.ABI
	dao                *dao.EventDAO // 引用 DAO 层
	lastProcessedBlock uint64
}

func NewEventListener(ethURL string, contractABI abi.ABI, dao *dao.EventDAO) (*EventController, error) {
	client, err := ethclient.Dial(ethURL)
	if err != nil {
		return nil, err
	}

	return &EventController{
		client:      client,
		contractABI: contractABI,
		dao:         dao,
	}, nil
}

func (el *EventController) StartListening(contractAddress common.Address, pollInterval time.Duration) {
	for {
		// 从本地文件加载最后已处理的区块高度
		lastProcessedBlock, err := el.loadLastProcessedBlockFromFile()
		if err != nil {
			fmt.Println("Error loading last processed block:", err)
			time.Sleep(pollInterval)
			continue
		}

		// 获取最新区块
		latestBlock, err := el.client.BlockByNumber(context.Background(), nil)
		if err != nil {
			fmt.Println("Error getting latest block:", err)
			time.Sleep(pollInterval)
			continue
		}

		fromBlock := lastProcessedBlock + 1 // 从上次处理的下一个区块开始
		toBlock := latestBlock.NumberU64()

		err = el.PollAndProcessLogs(contractAddress, fromBlock, toBlock)
		if err != nil {
			fmt.Println("Error polling and processing logs:", err)
		}

		// 更新最后一个已处理的区块高度
		el.lastProcessedBlock = toBlock

		// 将最后已处理的区块高度写入本地文件
		err = el.writeLastProcessedBlockToFile(el.lastProcessedBlock)
		if err != nil {
			fmt.Println("Error writing last processed block to file:", err)
		}

		time.Sleep(pollInterval)
	}
}

func (el *EventController) PollAndProcessLogs(contractAddress common.Address, fromBlock uint64, toBlock uint64) error {
	// 创建 Ethereum filter query
	// registerTopic := []common.Hash{el.contractABI.Events["Register"].ID}
	// createOptionTopic := []common.Hash{el.contractABI.Events["CreateOption"].ID}
	// withdrawTopic := []common.Hash{el.contractABI.Events["Withdraw"].ID}
	// claimWithPermitTopic := []common.Hash{el.contractABI.Events["ClaimWithPermit"].ID}

	// event Register(address registerAddress,address referrerAddress);
	// event CreateOption(address owner,uint256 optionId,uint256 amount,uint256 crateTime, Expiration expiration);
	// event Withdraw(address owner,uint256 optionId,uint256 amount);
	// event ClaimWithPermit(address owner,uint256 amountBNB);

	registerSig := []byte("Register(address,address)")
	registerSigHash := crypto.Keccak256Hash(registerSig)

	createOptionSig := []byte("CreateOption(address,uint256,uint256,uint256,uint8)")
	createOptionSigHash := crypto.Keccak256Hash(createOptionSig)

	withdrawSig := []byte("Withdraw(address,uint256,uint256)")
	withdrawSigHash := crypto.Keccak256Hash(withdrawSig)

	claimSig := []byte("ClaimWithPermit(address,uint256)")
	claimSigHash := crypto.Keccak256Hash(claimSig)

	//组装过滤条件
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
		// Topics: [][]common.Hash{
		// 	registerTopic,
		// 	createOptionTopic,
		// 	withdrawTopic,
		// 	claimWithPermitTopic,
		// },
		FromBlock: big.NewInt(int64(fromBlock)),
		ToBlock:   big.NewInt(int64(toBlock)),
	}

	//获取过滤事件结果
	logs, err := el.client.FilterLogs(context.Background(), query)
	if err != nil {
		return err
	}

	// 处理事件日志
	for _, log := range logs {
		switch log.Topics[0].Hex() {
		case registerSigHash.Hex():
			el.ProcessRegisterEvent(log)
			fmt.Println("抓取到了register结果")
		case createOptionSigHash.Hex():
			fmt.Println("我们看下错误前会有什么结果", log)
			// 处理 CreateOption 事件
			el.ProcessCreateOptionEvent(log)
			fmt.Println("抓取到了createOption结果")
		case withdrawSigHash.Hex():
			// 处理 Withdraw 事件
			el.ProcessWithdrawEvent(log)
			fmt.Println("抓取到了withdraw结果")
		case claimSigHash.Hex():
			// 处理 ClaimWithPermit 事件
			el.ProcessClaimWithPermitEvent(log)
			fmt.Println("抓取到了claim结果")
		default:
			// 未知事件类型
			fmt.Println("Unknown event type")

		}
	}

	return nil
}

// event Register(address registerAddress,address referrerAddress);

func (el *EventController) ProcessRegisterEvent(log types.Log) {
	var registerEvent struct {
		RegisterAddress common.Address
		ReferrerAddress common.Address
	}

	err := el.contractABI.UnpackIntoInterface(&registerEvent, "Register", log.Data)
	if err != nil {
		fmt.Println("Error unpacking Register event:", err)
		return
	}

	exists, err := el.dao.CheckIfTxHashExistsAcrossTables(log.TxHash)
	if err != nil {
		fmt.Println("Error checking if txHash exists:", err)
		return
	}

	if !exists {
		if err := el.dao.InsertRegisterEvent(registerEvent.RegisterAddress, registerEvent.ReferrerAddress, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

}

// event CreateOption(address owner,uint256 amount,uint256 crateTime, Expiration expiration);
func (el *EventController) ProcessCreateOptionEvent(log types.Log) {
	// 解析 CreateOption 事件数据
	var CreateOptionEvent struct {
		Owner      common.Address
		OptionId   *big.Int
		Amount     *big.Int
		CrateTime  *big.Int
		Expiration uint8 // Solidity 枚举类型 "Expiration" 对应的 Go 类型为 uint8
	}
	err := el.contractABI.UnpackIntoInterface(&CreateOptionEvent, "CreateOption", log.Data)
	if err != nil {
		fmt.Println("Error unpacking CreateOption event:", err)
		return
	}
	fmt.Println("这是CreateOptionEvent解析结果:", CreateOptionEvent)

	// 检查 MySQL 表是否已经存在具有相同 txHash 的记录
	exists, err := el.dao.CheckIfTxHashExistsAcrossTables(log.TxHash)
	if err != nil {
		fmt.Println("Error checking if txHash exists:", err)
		return
	}

	// 如果不存在相同 txHash 的记录，则插入数据
	if !exists {
		// owner common.Address, amount, createTime *big.Int, expiration int, txHash common.Hash
		if err := el.dao.InsertCreateOptionEvent(CreateOptionEvent.Owner, CreateOptionEvent.OptionId, CreateOptionEvent.Amount, CreateOptionEvent.CrateTime, CreateOptionEvent.Expiration, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

}

// event Withdraw(address owner,uint256 optionId,uint256 amount);
func (el *EventController) ProcessWithdrawEvent(log types.Log) {
	// 解析 Withdraw 事件数据
	var event struct {
		Owner    common.Address
		OptionId *big.Int
		Amount   *big.Int
	}
	err := el.contractABI.UnpackIntoInterface(&event, "Withdraw", log.Data)
	if err != nil {
		fmt.Println("Error unpacking Withdraw event:", err)
		return
	}

	if err := el.dao.UpdateBalance(event.Owner, event.Amount); err != nil {
		fmt.Println("Error inserting data into MySQL:", err)
	}

	// 其他逻辑继续...
}

// event ClaimWithPermit(address owner,uint256 amountBNB);
func (el *EventController) ProcessClaimWithPermitEvent(log types.Log) {
	// 解析 ClaimWithPermit 事件数据
	var event struct {
		Owner     common.Address
		AmountBNB *big.Int
	}
	err := el.contractABI.UnpackIntoInterface(&event, "ClaimWithPermit", log.Data)
	if err != nil {
		fmt.Println("Error unpacking ClaimWithPermit event:", err)
		return
	}

	// 检查 MySQL 表是否已经存在具有相同 txHash 的记录
	exists, err := el.dao.CheckIfTxHashExistsAcrossTables(log.TxHash)
	if err != nil {
		fmt.Println("Error checking if txHash exists:", err)
		return
	}

	// 如果不存在相同 txHash 的记录，则插入数据
	if !exists {
		if err := el.dao.InsertClaimWithPermitEvent(event.Owner, event.AmountBNB, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

	// 其他逻辑继续...
}

func (el *EventController) loadLastProcessedBlockFromFile() (uint64, error) {
	// 从本地文件加载最后已处理的区块高度
	data, err := os.ReadFile("block")
	if err != nil {
		return 0, err
	}

	// 解析文件内容为 uint64
	lastProcessedBlock, err := strconv.ParseUint(string(data), 10, 64)
	if err != nil {
		return 0, err
	}

	return lastProcessedBlock, nil
}

func (el *EventController) writeLastProcessedBlockToFile(blockNumber uint64) error {
	// 将最后已处理的区块高度转换为字符串
	blockNumberStr := strconv.FormatUint(blockNumber, 10)

	// 将字符串写入本地文件
	err := os.WriteFile("block", []byte(blockNumberStr), 0644)
	if err != nil {
		return err
	}

	return nil
}
