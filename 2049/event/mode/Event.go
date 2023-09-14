package mode

type Invitation struct {
	Id      int64  `xorm:"'id' pk autoincr"`
	Hash    string `xorm:"'hash' unique notnull"`
	Member  string `xorm:"'member' notnull"`
	Inviter string `xorm:"'inviter' notnull"`
}

type Order struct {
	Id         int64  `xorm:"'id' pk autoincr"`
	Hash       string `xorm:"'hash' unique notnull"`
	Owner      string `xorm:"'owner' notnull"`
	Value      string `xorm:"'value' notnull"` // Store Value as a string
	Expiration int    `xorm:"'expiration' notnull"`
}

type Withdrawal struct {
	Id       int64  `xorm:"'id' pk autoincr"`
	Hash     string `xorm:"'hash' unique notnull"`
	Receiver string `xorm:"'receiver' notnull"`
	Value    string `xorm:"'value' notnull"` // Store Value as a string
}
