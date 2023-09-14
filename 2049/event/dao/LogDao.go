package dao

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/jmoiron/sqlx"
)

type EventDAO struct {
	db *sqlx.DB
}

type CreateOption struct {
	Owner      common.Address
	Amount     *big.Int
	CrateTime  *big.Int
	Expiration common.Address
}

type Withdraw struct {
	Owner    common.Address
	OptionId *big.Int
	Amount   *big.Int
}

type ClaimWithPermit struct {
	Owner     common.Address
	AmountBNB *big.Int
}

// NewEventDAO 创建一个新的 EventDAO 实例
func NewEventDAO(db *sqlx.DB) *EventDAO {
	return &EventDAO{
		db: db,
	}
}

// CheckIfTxHashExists 查询是否已经存在具有相同 txHash 的记录
func (dao *EventDAO) CheckIfTxHashExists(txHash common.Hash) (bool, error) {
	var count int
	err := dao.db.Get(&count, "SELECT COUNT(*) FROM events WHERE tx_hash = ?", txHash.Hex())
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// InsertCreateOptionEvent 插入 CreateOption 事件数据到 MySQL 表
func (dao *EventDAO) InsertCreateOptionEvent(eventData CreateOption, txHash common.Hash) error {
	_, err := dao.db.Exec("INSERT INTO events (owner, amount, crate_time, expiration, tx_hash) VALUES (?, ?, ?, ?, ?)",
		eventData.Owner.Hex(), eventData.Amount.String(), eventData.CrateTime.String(), eventData.Expiration.Hex(), txHash.Hex())
	return err
}

// InsertWithdrawEvent 插入 Withdraw 事件数据到 MySQL 表
func (dao *EventDAO) InsertWithdrawEvent(eventData Withdraw, txHash common.Hash) error {
	_, err := dao.db.Exec("INSERT INTO events (owner, option_id, amount, tx_hash) VALUES (?, ?, ?, ?)",
		eventData.Owner.Hex(), eventData.OptionId.String(), eventData.Amount.String(), txHash.Hex())
	return err
}

// InsertClaimWithPermitEvent 插入 ClaimWithPermit 事件数据到 MySQL 表
func (dao *EventDAO) InsertClaimWithPermitEvent(eventData ClaimWithPermit, txHash common.Hash) error {
	_, err := dao.db.Exec("INSERT INTO events (owner, amount_bnb, tx_hash) VALUES (?, ?, ?)",
		eventData.Owner.Hex(), eventData.AmountBNB.String(), txHash.Hex())
	return err
}
