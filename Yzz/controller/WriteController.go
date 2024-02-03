package controller

import (
	"Yzz/mode"
	"Yzz/utils"
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"math/big"
	"strconv"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/gin-gonic/gin"
)

// function distributeRankings(address[] memory members,Target target,string memory mark) external;
func (mc *MembershipController) DistributeRankings(ctx *gin.Context) {
	var param mode.Reward
	if err := json.NewDecoder(ctx.Request.Body).Decode(&param); err != nil {
		utils.Failed(ctx, "distributeRankings参数解析失败")
		return
	}
	members, err := convertToAddress(param.Members)
	if err != nil {
		utils.Failed(ctx, "distributeRanking函数string类型转为common.address类型失败")
		return
	}

	target, err := stringToUint8(param.Target)
	if err != nil {
		utils.Failed(ctx, "string类型转uint8失败!")
		return
	}

	input, err := mc.contractABI.Pack("distributeRankings", members, target, param.Mark)
	if err != nil {
		utils.Failed(ctx, "组装distributeRankings输入参数失败")
		return
	}
	tx, err := mc.sendTransations(input)
	if err != nil {
		utils.Failed(ctx, "发送distributeRankings交易失败")
		return
	}
	utils.Success(ctx, tx.Hash())
}

func (mc *MembershipController) sendTransations(input []byte) (*types.Transaction, error) {
	privateKey, err := crypto.HexToECDSA(mc.cfg.Contract.PrivateKey)
	if err != nil {

		fmt.Println("私钥转换失败", err)
		return nil, err
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		fmt.Println("私钥派生钱包地址失败", err)
		return nil, err
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	nonce, err := mc.client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		fmt.Println("获取nonce值失败", err)
		return nil, err

	}

	gasPrice, err := mc.client.SuggestGasPrice(context.Background())

	if err != nil {
		fmt.Println("获取gasPrice失败", err)
		return nil, err
	}

	gaslimit, err := strconv.ParseUint(mc.cfg.RPC.Gaslimit, 10, 64)
	if err != nil {
		fmt.Println("gaslimit转换失败:", err)
		return nil, err
	}
	multiple := new(big.Int)
	multiple.SetString(mc.cfg.RPC.Multiple, 10)
	gasPrice.Mul(gasPrice, multiple)
	tx := types.NewTransaction(nonce, common.HexToAddress(mc.cfg.Contract.Membership), big.NewInt(0), gaslimit, gasPrice, input)
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(big.NewInt(56)), privateKey)
	if err != nil {
		fmt.Println("交易签名失败:", err)
		return nil, err
	}

	err = mc.client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		fmt.Println("发送交易失败:", err)
		return nil, err
	}
	return signedTx, nil
}
