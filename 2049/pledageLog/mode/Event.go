package mode

// event Provide(address owner, uint256 amount, uint256 time, Expiration expiration);
type Provide struct {
	Id         int64  `xorm:"'id' pk autoincr"`
	Hash       string `xorm:"'hash' notnull varchar(255)"`
	Owner      string `xorm:"'owner' notnull varchar(255)"`
	Amount     string `xorm:"'amount' notnull varchar(255)"`
	Time       string `xorm:"'time' notnull varchar(255)"`
	Expiration uint8  `xorm:"'expiration' notnull varchar(255)"`
}

// event Withdraw(uint256 orderId, address receiver, address token, uint256 amount);
type Withdraw struct {
	Id       int64  `xorm:"'id' pk autoincr"`
	Hash     string `xorm:"'hash' notnull varchar(255)"`
	OrderId  string `xorm:"'order_id' notnull varchar(255)"`
	Receiver string `xorm:"'receiver' notnull varchar(255)"`
	Token    string `xorm:"'token' varchar(255)"`
	Amount   string `xorm:"'amount' notnull varchar(255)"`
	Time     string `xorm:"'time' notnull varchar(255)"`
}
