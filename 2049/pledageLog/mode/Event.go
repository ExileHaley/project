package mode

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

type Register struct {
	Id       int64          `xorm:"'id' pk autoincr"`
	Hash     common.Hash    `xorm:"'hash' notnull varchar(255)"`
	Member   common.Address `xorm:"'member' notnull varchar(255)"`
	Referrer common.Address `xorm:"'referrer' notnull varchar(255)"`
}

type Option struct {
	Id         int64          `xorm:"'id' pk autoincr"`
	Hash       common.Hash    `xorm:"'hash' notnull varchar(255)"`
	Owner      common.Address `xorm:"'owner' notnull varchar(255)"`
	Amount     *big.Int       `xorm:"'amount' notnull BigInt"`
	CreateTime *big.Int       `xorm:"'create_time' notnull BigInt"`
	Expiration int            `xorm:"'expiration' notnull varchar(255)"`
}

type Claim struct {
	Id       int64          `xorm:"'id' pk autoincr"`
	Hash     common.Hash    `xorm:"'hash' notnull varchar(255)"`
	Receiver common.Address `xorm:"'receiver' notnull varchar(255)"`
	Balance  *big.Int       `xorm:"'balance' notnull BigInt"`
}
