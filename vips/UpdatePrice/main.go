package main

import (
	vip "UpdatePrice/contract"
	"context"
	"crypto/ecdsa"
	"errors"
	"fmt"
	"time"

	"log"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

var rpc = "https://rpc-bsc.48.club"
var contractAddress = ""
var sendPrivateKey = "YOUR_PRIVATE_KEY"

func main() {
	client, err := ethclient.Dial(rpc)

	if err != nil {
		log.Fatal("Create node failed", err)
	}

	for {
		tx, err := process(client)
		if err != nil {
			fmt.Println("func main update price failed")
			continue
		}
		fmt.Println("update price txHash:", tx.Hash().Hex())
		time.Sleep(time.Minute * 10)
	}

}

func process(client *ethclient.Client) (*types.Transaction, error) {
	var newPriceInt64 int64
	var err error
	// 不断尝试获取价格，直到获取成功为止
	for {
		newPriceInt64, err = getNewPrice()
		if err == nil {
			break // 如果获取成功，退出内部循环
		}
		log.Println("Get new price failed, retrying in 1 minute:", err)
		time.Sleep(time.Minute) // 等待1分钟后重试
	}

	tx, err := updatePrice(client, big.NewInt(newPriceInt64*100))
	return tx, err

}

func getNewPrice() (int64, error) {
	return 0, nil
}

func updatePrice(client *ethclient.Client, newPrice *big.Int) (*types.Transaction, error) {
	var tx *types.Transaction
	vipInstance, err := vip.NewVip(common.HexToAddress(contractAddress), client)
	if err != nil {
		return nil, err
	}

	price, err := vipInstance.TokenPrice(nil)
	if err != nil {
		return nil, err
	}
	diff := new(big.Int)
	diff.Sub(newPrice, price)

	percentageChange := new(big.Rat).SetFrac(diff, price)
	tenPercent := new(big.Rat).SetFrac(big.NewInt(10), big.NewInt(100))

	compareResult := percentageChange.Cmp(tenPercent)

	privateKey, err := crypto.HexToECDSA(strings.TrimSpace(sendPrivateKey))
	if err != nil {
		return nil, err
	}
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, big.NewInt(56))
	if err != nil {
		return nil, err
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, errors.New("parse from address failed")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA).Hex()
	nonce, err := client.PendingNonceAt(context.Background(), common.HexToAddress(fromAddress))
	if err != nil {
		return nil, err
	}
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		return nil, err
	}
	auth.Nonce = big.NewInt(int64(nonce))
	auth.GasPrice = gasPrice

	if compareResult > 0 {

		tx, err = vipInstance.UpdatePrice(auth, newPrice)
		if err != nil {
			return tx, err
		}

	}
	return tx, nil
}
