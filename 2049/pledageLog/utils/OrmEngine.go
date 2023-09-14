package utils

import (
	"pledageLog/mode"

	_ "github.com/go-sql-driver/mysql"
	"github.com/go-xorm/xorm"
)

var Engine *xorm.Engine

func NewEngine(cfg *Config) (*xorm.Engine, error) {
	baseCfg := cfg.MySQL
	dsn := baseCfg.User + ":" + baseCfg.Password + "@tcp(" + baseCfg.Host + ":" + baseCfg.Port + ")/" + baseCfg.Database
	engine, err := xorm.NewEngine("mysql", dsn)
	if err != nil {
		return nil, err
	}
	engine.ShowSQL(baseCfg.ShowSql)
	engine.Sync2(new(mode.Register), new(mode.Option), new(mode.Claim))
	return Engine, nil
}
