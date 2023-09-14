package main

import (
	"fmt"
	"pledageLog/dao"
	"pledageLog/utils"
)

func main() {
	cfg, err := utils.ParseConfig("./config.json")
	if err != nil {
		fmt.Println("解析配置文件失败!", err)
		return
	}
	fmt.Println("配置文件内容:", cfg)
	ormEngine, err := utils.NewEngine(cfg)
	if err != nil {
		fmt.Println("初始化Xorm失败!", err)
		return
	}
	eventDAO := dao.NewEventDAO(ormEngine)

	// // 合约 ABI

	// // 以太坊节点 URL
	// ethURL := "https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID"

	// // 创建事件监听器
	// eventListener, err := controller.NewEventListener(ethURL, contractABI, eventDAO)
	// if err != nil {
	// 	fmt.Println("Error creating event listener:", err)
	// 	return
	// }

	// // 启动事件监听器
	// go eventListener.StartListening(common.HexToAddress("YOUR_CONTRACT_ADDRESS"), 10*time.Second)
}
