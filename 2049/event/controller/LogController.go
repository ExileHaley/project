package eventlistener

import (
	"context"
	"event/dao"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

type EventListener struct {
	client      *ethclient.Client
	contractABI abi.ABI
	dao         *dao.EventDAO // 引用 DAO 层
}

func NewEventListener(client *ethclient.Client, contractABI abi.ABI, dao *dao.EventDAO) *EventListener {
	return &EventListener{
		client:      client,
		contractABI: contractABI,
		dao:         dao,
	}
}

func (el *EventListener) LogListener(contractAddress common.Address) {
	// 创建 Ethereum filter query
	createOptionTopic := []common.Hash{el.contractABI.Events["CreateOption"].ID}
	withdrawTopic := []common.Hash{el.contractABI.Events["Withdraw"].ID}
	claimWithPermitTopic := []common.Hash{el.contractABI.Events["ClaimWithPermit"].ID}

	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
		Topics: [][]common.Hash{
			createOptionTopic,
			withdrawTopic,
			claimWithPermitTopic,
		},
	}

	logs := make(chan types.Log)
	sub, err := el.client.SubscribeFilterLogs(context.Background(), query, logs)
	if err != nil {
		log.Fatal(err)
	}
	defer sub.Unsubscribe()

	// Listen for and process events
	for {
		select {
		case err := <-sub.Err():
			log.Fatal(err)
		case log := <-logs:
			// 确定事件类型并处理
			switch {
			case log.Topics[0] == createOptionTopic[0]:
				// 处理 CreateOption 事件
				el.ProcessCreateOptionEvent(log)
				// 处理其他事件类似...
			case log.Topics[0] == withdrawTopic[0]:
				// 处理 Withdraw 事件
				el.ProcessWithdrawEvent(log)
			case log.Topics[0] == claimWithPermitTopic[0]:
				// 处理 ClaimWithPermit 事件
				el.ProcessClaimWithPermitEvent(log)
			default:
				// 未知事件类型
				fmt.Println("Unknown event type")

			}
		}
	}
}

func (el *EventListener) ProcessCreateOptionEvent(log types.Log) {
	// 解析 CreateOption 事件数据
	var event struct {
		Owner      common.Address
		Amount     *big.Int
		CrateTime  *big.Int
		Expiration common.Address
	}
	err := el.contractABI.UnpackIntoInterface(&event, "CreateOption", log.Data)
	if err != nil {
		fmt.Println("Error unpacking CreateOption event:", err)
		return
	}

	// 检查 MySQL 表是否已经存在具有相同 txHash 的记录
	exists, err := el.dao.CheckIfTxHashExists(log.TxHash)
	if err != nil {
		fmt.Println("Error checking if txHash exists:", err)
		return
	}

	// 如果不存在相同 txHash 的记录，则插入数据
	if !exists {
		if err := el.dao.InsertCreateOptionEvent(event, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

	// 其他逻辑继续...
}
