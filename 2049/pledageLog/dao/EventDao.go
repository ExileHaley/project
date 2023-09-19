package dao

import (
	"fmt"
	"math/big"
	"pledageLog/mode"

	"github.com/ethereum/go-ethereum/common"
	"github.com/go-xorm/xorm"
)

type EventDAO struct {
	engine *xorm.Engine
}

// NewEventDAO 创建一个新的 EventDAO 实例
func NewEventDAO(engine *xorm.Engine) *EventDAO {
	return &EventDAO{
		engine: engine,
	}
}

// CheckIfTxHashExistsAcrossTables 查询是否已经存在具有相同 txHash 的记录，跨多个事件表
func (dao *EventDAO) CheckIfTxHashExistsAcrossTables(txHash common.Hash) (bool, error) {
	count, err := dao.engine.
		Where("hash = ?", txHash.Hex()).
		Count(new(mode.Provide), new(mode.Withdraw))
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (dao *EventDAO) InsertProvideEvent(owner common.Address, amount, time *big.Int, expiration uint8, hash common.Hash) error {

	provideData := mode.Provide{
		Hash:       hash.Hex(),
		Owner:      owner.Hex(),
		Amount:     amount.String(),
		Time:       time.String(),
		Expiration: expiration,
	}
	fmt.Println("用户创建订单记录:", provideData)
	_, err := dao.engine.Insert(&provideData)
	if err != nil {
		fmt.Println("Error inserting data into MySQL:", err)
		return err
	}

	return nil
}

// (withdrawEvent.OrderId, withdrawEvent.Receiver, withdrawEvent.Token, withdrawEvent.Amount, withdrawEvent.Time, log.TxHash)
func (dao *EventDAO) InsertWithdrawEvent(orderId *big.Int, receiver, token common.Address, amount, time *big.Int, hash common.Hash) error {

	withdrawData := mode.Withdraw{
		Hash:     hash.Hex(),
		OrderId:  orderId.String(),
		Receiver: receiver.Hex(),
		Token:    token.Hex(),
		Amount:   amount.String(),
		Time:     time.String(),
	}
	fmt.Println("用户创建订单记录:", withdrawData)
	_, err := dao.engine.Insert(&withdrawData)
	if err != nil {
		fmt.Println("Error inserting data into MySQL:", err)
		return err
	}

	return nil
}
