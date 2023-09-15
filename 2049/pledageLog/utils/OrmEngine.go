package utils

import (
	"fmt"
	"pledageLog/mode"

	_ "github.com/go-sql-driver/mysql"
	"github.com/go-xorm/xorm"
)

func NewEngine(cfg *Config) (*xorm.Engine, error) {
	baseCfg := cfg.MySQL
	dsn := baseCfg.User + ":" + baseCfg.Password + "@tcp(" + baseCfg.Host + ":" + baseCfg.Port + ")/" + baseCfg.Database
	fmt.Println("dsn:", dsn)
	engine, err := xorm.NewEngine("mysql", dsn)
	if err != nil {
		return nil, err
	}
	engine.ShowSQL(baseCfg.ShowSql)
	err = engine.Sync2(new(mode.Register), new(mode.Option), new(mode.Claim))
	if err != nil {
		fmt.Println("数据库表同步错误:", err)
	}
	return engine, nil // 返回 engine 而不是 Engine
}
