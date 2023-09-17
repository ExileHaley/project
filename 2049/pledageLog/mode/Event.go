package mode

type Register struct {
	Id       int64  `xorm:"'id' pk autoincr"`
	Hash     string `xorm:"'hash' notnull varchar(255)"`
	Member   string `xorm:"'member' notnull varchar(255)"`
	Referrer string `xorm:"'referrer' notnull varchar(255)"`
}

type Option struct {
	Id         int64  `xorm:"'id' pk autoincr"`
	Hash       string `xorm:"'hash' notnull varchar(255)"`
	Owner      string `xorm:"'owner' notnull varchar(255)"`
	OptionId   string `xorm:"'option_id' notnull varchar(255)"`
	Amount     string `xorm:"'amount' notnull varchar(255)"`
	CreateTime string `xorm:"'create_time' notnull varchar(255)"`
	Expiration uint8  `xorm:"'expiration' notnull varchar(255)"`
}

type Claim struct {
	Id       int64  `xorm:"'id' pk autoincr"`
	Hash     string `xorm:"'hash' notnull varchar(255)"`
	Receiver string `xorm:"'receiver' notnull varchar(255)"`
	Balance  string `xorm:"'balance' notnull varchar(255)"`
}
