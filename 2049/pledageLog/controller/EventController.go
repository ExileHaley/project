package controller

import (
	"context"
	"fmt"
	"math/big"
	"pledageLog/dao"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

type EventController struct {
	client      *ethclient.Client
	contractABI abi.ABI
	dao         *dao.EventDAO // 引用 DAO 层
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
		//获取最新区块
		latestBlock, err := el.client.BlockByNumber(context.Background(), nil)
		if err != nil {
			fmt.Println("Error getting latest block:", err)
			time.Sleep(pollInterval)
			continue
		}

		fromBlock := latestBlock.NumberU64()
		toBlock := fromBlock

		err = el.PollAndProcessLogs(contractAddress, fromBlock, toBlock)
		if err != nil {
			fmt.Println("Error polling and processing logs:", err)
		}

		time.Sleep(pollInterval)
	}
}

func (el *EventController) PollAndProcessLogs(contractAddress common.Address, fromBlock uint64, toBlock uint64) error {
	// 创建 Ethereum filter query
	registerTopic := []common.Hash{el.contractABI.Events["Register"].ID}
	createOptionTopic := []common.Hash{el.contractABI.Events["CreateOption"].ID}
	withdrawTopic := []common.Hash{el.contractABI.Events["Withdraw"].ID}
	claimWithPermitTopic := []common.Hash{el.contractABI.Events["ClaimWithPermit"].ID}
	//组装过滤条件
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
		Topics: [][]common.Hash{
			registerTopic,
			createOptionTopic,
			withdrawTopic,
			claimWithPermitTopic,
		},
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
		switch {
		case strings.HasPrefix(log.Topics[0].Hex(), registerTopic[0].Hex()):

		case strings.HasPrefix(log.Topics[0].Hex(), createOptionTopic[0].Hex()):
			// 处理 CreateOption 事件
			el.ProcessCreateOptionEvent(log)
		case strings.HasPrefix(log.Topics[0].Hex(), withdrawTopic[0].Hex()):
			// 处理 Withdraw 事件
			el.ProcessWithdrawEvent(log)
		case strings.HasPrefix(log.Topics[0].Hex(), claimWithPermitTopic[0].Hex()):
			// 处理 ClaimWithPermit 事件
			el.ProcessClaimWithPermitEvent(log)
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
		registerAddress common.Address
		referrerAddress common.Address
	}

	err := el.contractABI.UnpackIntoInterface(&registerEvent, "CreateOption", log.Data)
	if err != nil {
		fmt.Println("Error unpacking CreateOption event:", err)
		return
	}

	exists, err := el.dao.CheckIfTxHashExistsAcrossTables(log.TxHash)
	if err != nil {
		fmt.Println("Error checking if txHash exists:", err)
		return
	}

	if !exists {
		if err := el.dao.InsertRegisterEvent(registerEvent.registerAddress, registerEvent.referrerAddress, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

}

// event CreateOption(address owner,uint256 amount,uint256 crateTime, Expiration expiration);
func (el *EventController) ProcessCreateOptionEvent(log types.Log) {
	// 解析 CreateOption 事件数据
	var event struct {
		Owner      common.Address
		Amount     *big.Int
		CrateTime  *big.Int
		Expiration int
	}
	err := el.contractABI.UnpackIntoInterface(&event, "CreateOption", log.Data)
	if err != nil {
		fmt.Println("Error unpacking CreateOption event:", err)
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
		// owner common.Address, amount, createTime *big.Int, expiration int, txHash common.Hash
		if err := el.dao.InsertCreateOptionEvent(event.Owner, event.Amount, event.CrateTime, event.Expiration, log.TxHash); err != nil {
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
