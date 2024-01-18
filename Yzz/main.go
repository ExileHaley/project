package main

import (
	"Yzz/controller"
	"Yzz/utils"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/gin-gonic/gin"
)

func main() {
	cfg, err := utils.ParseConfig("./config.json")
	if err != nil {
		fmt.Println("解析配置文件失败!", err)
		return
	}

	file, err := os.Open("./abi/IMembership.abi")
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

	membership, err := controller.NewWriteController(cfg, contractABI)
	if err != nil {
		log.Fatal("创建controller实例失败:", err)
		return
	}
	app := gin.Default()
	app.GET("/getRankings", func(ctx *gin.Context) {
		membership.GetRankings(ctx)
	})
	app.GET("/getResult", func(ctx *gin.Context) {
		membership.GetExtractedResult(ctx)
	})
	app.POST("/getGrades", func(ctx *gin.Context) {
		membership.GetMemberGrades(ctx)
	})
	app.POST("/multiGetGrades", func(ctx *gin.Context) {
		membership.MultiGetMemberGrades(ctx)
	})

	app.POST("/distribute", func(ctx *gin.Context) {
		membership.DistributeRankings(ctx)
	})
	app.Run(":" + cfg.GIN.Port)
}
