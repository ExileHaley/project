package controller

import (
	"encoding/hex"
	"encoding/json"
	"net/http"
	"pledageLog/utils"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/gin-gonic/gin"
)

type ClaimController struct {
	contractAddress common.Address
	client          *ethclient.Client
}

type Content struct {
	Token   string `json:"token"`
	Holder  string `json:"holder"`
	Amount  string `json:"amount"`
	OrderId string `json:"orderId"`
	V       uint8  `json:"v"`
	R       string `json:"r"`
	S       string `json:"s"`
}

type Param struct {
	Token   string `json:"token"`
	Holder  string `json:"holder"`
	Amount  string `json:"amount"`
	OrderId string `json:"orderId"`
}

func SetupClaimController(ethURL string, contract common.Address) (*ClaimController, error) {
	// 初始化控制器实例
	client, err := ethclient.Dial(ethURL)
	if err != nil {
		return nil, err
	}
	claimController := &ClaimController{
		client:          client,
		contractAddress: contract,
	}

	return claimController, nil
}

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
		Holder string `json:"holder"`
		Amount string `json:"amount"`
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
		R:      hex.EncodeToString(signature[:32]),
		S:      hex.EncodeToString(signature[32:64]),
	}

	ctx.JSON(http.StatusOK, content)
}

func (claim *ClaimController) GetPrice(ctx *gin.Context) {
	currency, exist := ctx.GetQuery("currency")
	if !exist {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "currency parameter is missing"})
		return
	}

	// Call different methods based on the currency value
	switch currency {
	case "bnb":
		price, err := claim.getPriceForBnb(claim.client, claim.contractAddress)
		if err != nil {
			ctx.JSON(http.StatusOK, gin.H{"Error": err})
			return
		}
		ctx.JSON(http.StatusOK, gin.H{"currency": currency, "price": price})
		return
	case "token":
		price, err := claim.getPriceForToken(claim.client, claim.contractAddress)
		if err != nil {
			ctx.JSON(http.StatusOK, gin.H{"Error": err})
			return
		}
		ctx.JSON(http.StatusOK, gin.H{"currency": currency, "price": price})
		return
	default:
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "unsupported currency"})
		return
	}
}

func (claim *ClaimController) getPriceForBnb(client *ethclient.Client, contract common.Address) (string, error) {

	contractInstance, err := NewContract(contract, client)
	if err != nil {
		return "", err
	}
	price, err := contractInstance.GetBnbPrice(nil)
	if err != nil {
		return "", err
	}
	priceString := price.String()
	return priceString, nil

}

func (claim *ClaimController) getPriceForToken(client *ethclient.Client, contract common.Address) (string, error) {

	contractInstance, err := NewContract(contract, client)
	if err != nil {
		return "", err
	}
	price, err := contractInstance.GetTokenPrice(nil)
	if err != nil {
		return "", err
	}
	priceString := price.String()
	return priceString, nil

}
