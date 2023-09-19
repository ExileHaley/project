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

func (el *EventController) StartListening(contractAddress common.Address, pollInterval time.Duration, blockBatchSize uint64) {
	for {
		lastProcessedBlock, err := el.loadLastProcessedBlockFromFile()
		if err != nil {
			fmt.Println("Error loading last processed block:", err)
			time.Sleep(pollInterval)
			continue
		}

		latestBlock, err := el.client.BlockByNumber(context.Background(), nil)
		if err != nil {
			fmt.Println("Error getting latest block:", err)
			time.Sleep(pollInterval)
			continue
		}

		fromBlock := lastProcessedBlock + 1
		toBlock := latestBlock.NumberU64()

		for fromBlock < toBlock {
			endBlock := fromBlock + blockBatchSize - 1
			if endBlock > toBlock {
				endBlock = toBlock
			}

			err = el.PollAndProcessLogs(contractAddress, fromBlock, endBlock)
			if err != nil {
				fmt.Printf("Error polling and processing logs for blocks %d to %d: %v\n", fromBlock, endBlock, err)
			}

			fromBlock = endBlock + 1
		}

		el.lastProcessedBlock = toBlock

		err = el.writeLastProcessedBlockToFile(el.lastProcessedBlock)
		if err != nil {
			fmt.Println("Error writing last processed block to file:", err)
		}

		time.Sleep(pollInterval)
	}
}

func (el *EventController) PollAndProcessLogs(contractAddress common.Address, fromBlock uint64, toBlock uint64) error {
	fmt.Println("Event listener started.")
	// event Provide(address owner, uint256 amount, uint256 time, Expiration expiration);
	// event Withdraw(uint256 orderId, address receiver, address token, uint256 amount,uint256 time);
	provideSig := []byte("Provide(address,uint256,uint256,uint8)")
	provideSigHash := crypto.Keccak256Hash(provideSig)

	WithdrawSig := []byte("Withdraw(uint256,address,address,uint256,uint256)")
	WithdrawSigHash := crypto.Keccak256Hash(WithdrawSig)

	//组装过滤条件
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
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
		case provideSigHash.Hex():
			el.ProcessProvideEvent(log)
			fmt.Println("走到充值数据抓取了")
		case WithdrawSigHash.Hex():
			// 处理 CreateOption 事件
			el.ProcessWithdrawEvent(log)
			fmt.Println("走到提现数据抓取了")
		default:
			// 未知事件类型
			fmt.Println("Unknown event type")

		}
	}

	return nil
}

// event Provide(address owner, uint256 amount, uint256 time, Expiration expiration);

func (el *EventController) ProcessProvideEvent(log types.Log) {
	var provideEvent struct {
		Owner      common.Address
		Amount     *big.Int
		Time       *big.Int
		Expiration uint8
	}

	err := el.contractABI.UnpackIntoInterface(&provideEvent, "Provide", log.Data)
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
		if err := el.dao.InsertProvideEvent(provideEvent.Owner, provideEvent.Amount, provideEvent.Time, provideEvent.Expiration, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

}

// event Withdraw(uint256 orderId, address receiver, address token, uint256 amount,uint256 time);
func (el *EventController) ProcessWithdrawEvent(log types.Log) {
	// 解析 withdraw 事件数据
	var withdrawEvent struct {
		OrderId  *big.Int
		Receiver common.Address
		Token    common.Address
		Amount   *big.Int
		Time     *big.Int
	}
	err := el.contractABI.UnpackIntoInterface(&withdrawEvent, "CreateOption", log.Data)
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

		if err := el.dao.InsertWithdrawEvent(withdrawEvent.OrderId, withdrawEvent.Receiver, withdrawEvent.Token, withdrawEvent.Amount, withdrawEvent.Time, log.TxHash); err != nil {
			fmt.Println("Error inserting data into MySQL:", err)
		}
	}

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
