package controller

import (
	"encoding/hex"
	"encoding/json"
	"math/big"
	"net/http"
	"pledageLog/utils"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/gin-gonic/gin"
)

type ClaimController struct{}

type Content struct {
	Holder string   `json:"holder"`
	Amount *big.Int `json:"amount"`
	V      uint8    `json:"v"`
	R      bytes32  `json:"r"`
	S      bytes32  `json:"s"`
}

type Param struct {
	Holder string   `json:"holder"`
	Amount *big.Int `json:"amount"`
}

type address string
type bytes32 [32]byte

func (claim *ClaimController) SignParam(ctx *gin.Context, cfg *utils.Config) {
	var param Param
	if err := json.NewDecoder(ctx.Request.Body).Decode(&param); err != nil {
		ctx.JSON(http.StatusOK, map[string]interface{}{
			"data": "参数解析失败",
		})
		return
	}

	// Decode private key
	privateKeyHex := cfg.Contract.PrivateKey
	privateKey, err := crypto.HexToECDSA(privateKeyHex)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "无法加载私钥",
		})
		return
	}

	// Prepare the EIP-712 domain separator
	domainSeparatorHex := cfg.Contract.DomainSeparator
	domainSeparator, err := hex.DecodeString(domainSeparatorHex)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "无法解析 domainSeparator",
		})
		return
	}

	// Construct the message
	message := struct {
		Holder string   `json:"holder"`
		Amount *big.Int `json:"amount"`
	}{
		Holder: param.Holder,
		Amount: param.Amount,
	}

	// Marshal the message to JSON
	messageJSON, err := json.Marshal(message)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "无法序列化消息",
		})
		return
	}

	// Hash the message
	messageHash := crypto.Keccak256(
		append(domainSeparator, messageJSON...),
	)

	// Sign the message hash
	signature, err := crypto.Sign(messageHash, privateKey)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "签名失败",
		})
		return
	}

	content := Content{
		Holder: param.Holder,
		Amount: param.Amount,
		V:      signature[64] + 27,
	}
	copy(content.R[:], signature[:32])
	copy(content.S[:], signature[32:64])

	ctx.JSON(http.StatusOK, content)
}
