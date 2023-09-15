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
		Where("tx_hash = ?", txHash.Hex()).
		Count(new(mode.Option), new(mode.Register), new(mode.Claim))
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// InsertCreateOptionEvent 插入 CreateOption 事件数据到对应的表
func (dao *EventDAO) InsertCreateOptionEvent(owner common.Address, amount, createTime *big.Int, expiration uint8, txHash common.Hash) error {
	optionData := mode.Option{
		Hash:       txHash,
		Owner:      owner,
		Amount:     amount,
		CreateTime: createTime,
		Expiration: expiration,
	}

	fmt.Printf("Inserting option data: %+v\n", optionData)

	_, err := dao.engine.Insert(&optionData)
	if err != nil {
		fmt.Println("Error inserting data into MySQL:", err)
	}

	return err
}

// UpdateBalance 更新数据库中 Owner 的余额，执行 Withdraw 事件
func (dao *EventDAO) UpdateBalance(owner common.Address, withdrawValue *big.Int) error {
	// 获取当前 Owner 的余额
	var currentBalance big.Int
	has, err := dao.engine.Where("owner = ?", owner.Hex()).Get(&currentBalance)
	if err != nil {
		return err
	}

	if !has {
		return fmt.Errorf("Owner not found")
	}

	// 检查余额是否足够
	if currentBalance.Cmp(withdrawValue) < 0 {
		return fmt.Errorf("Insufficient balance for withdrawal")
	}

	// 计算新的余额
	newBalance := new(big.Int).Sub(&currentBalance, withdrawValue)

	// 开始事务
	session := dao.engine.NewSession()
	defer session.Close()

	// 启动事务
	err = session.Begin()
	if err != nil {
		return err
	}

	// 更新 option 表中的余额
	affected, err := session.Where("owner = ?", owner.Hex()).Update(&mode.Option{Amount: newBalance})
	if err != nil {
		session.Rollback()
		return err
	}

	if affected != 1 {
		session.Rollback()
		return fmt.Errorf("Failed to update option table")
	}

	// 提交事务
	err = session.Commit()
	if err != nil {
		session.Rollback()
		return err
	}

	return nil
}

// InsertClaimWithPermitEvent 插入 ClaimWithPermit 事件数据到对应的表
func (dao *EventDAO) InsertClaimWithPermitEvent(receiver common.Address, amount *big.Int, txHash common.Hash) error {
	claimData := mode.Claim{
		Hash:     txHash,
		Receiver: receiver,
		Balance:  amount,
	}
	_, err := dao.engine.Insert(&claimData)
	return err
}

// InsertRegisterEvent 插入 Register 事件数据到对应的表
func (dao *EventDAO) InsertRegisterEvent(registerAddress common.Address, referrerAddress common.Address, txHash common.Hash) error {
	// 将 eventData 和 txHash 插入数据库
	registerData := mode.Register{
		Member:   registerAddress,
		Referrer: referrerAddress,
		Hash:     txHash,
	}
	_, err := dao.engine.Insert(&registerData)
	if err != nil {
		return err
	}

	return nil
}
