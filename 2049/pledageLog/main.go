package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"pledageLog/controller"
	"pledageLog/dao"
	"pledageLog/utils"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/gin-gonic/gin"
)

func main() {
	cfg, err := utils.ParseConfig("./config.json")
	if err != nil {
		fmt.Println("解析配置文件失败!", err)
		return
	}

	ormEngine, err := utils.NewEngine(cfg)
	if err != nil {
		fmt.Println("初始化Xorm失败!", err)
		return
	}

	eventDAO := dao.NewEventDAO(ormEngine)

	file, err := os.Open("./contract/Pledage.abi")
	if err != nil {
		log.Fatal("打开 abi 文件失败:", err)
		return
	}
	defer file.Close()

	content, err := io.ReadAll(file)
	if err != nil {
		log.Fatal("读取 abi 文件内容失败:", err)
		return
	}

	contractABI, err := abi.JSON(strings.NewReader(string(content)))
	if err != nil {
		log.Fatal(err)
	}

	// // 创建事件监听器
	eventListener, err := controller.NewEventListener(cfg.RPC.URL, contractABI, eventDAO)
	if err != nil {
		fmt.Println("创建监听进程实例失败:", err)
		return
	}
	defer ormEngine.Close()

	// // 启动事件监听器
	eventListener.StartListening(common.HexToAddress(cfg.RPC.ContractAddress), 10*time.Second)

	app := gin.Default()
	claimController := new(controller.ClaimController)

	// Register the router with the config
	app.GET("/signer", func(ctx *gin.Context) {
		claimController.SignParam(ctx, cfg)
	})

	//运行gin框架
	app.Run(":" + cfg.GIN.Port)

}

// func registerRouter(engine *gin.Engine, cfg *utils.Config) {
// 	new(controller.ClaimController).Router(engine, cfg)

// }
