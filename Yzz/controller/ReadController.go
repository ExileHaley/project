package controller

import (
	"Yzz/mode"
	"Yzz/utils"
	"context"
	"encoding/json"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/gin-gonic/gin"
)

type MembershipController struct {
	client      *ethclient.Client
	cfg         *utils.Config
	contractABI abi.ABI
}

func NewWriteController(_cfg *utils.Config, _membershipABI abi.ABI) (*MembershipController, error) {
	// 初始化控制器实例
	_client, err := ethclient.Dial(_cfg.RPC.URL)
	if err != nil {
		return nil, err
	}
	writeController := &MembershipController{
		client:      _client,
		cfg:         _cfg,
		contractABI: _membershipABI,
	}

	return writeController, nil
}

// function getRankings(Target target) external view returns(address[] memory);
func (mc *MembershipController) GetRankings(ctx *gin.Context) {
	_target, exist := ctx.GetQuery("target")
	if !exist {
		utils.Failed(ctx, "获取列表方法解析参数失败!")
		return
	}
	target, err := stringToUint8(_target)
	if err != nil {
		utils.Failed(ctx, "string类型转uint8失败!")
		return
	}
	//function getRankings(Target target) external view returns(address[] memory);
	input, err := mc.contractABI.Pack("getRankings", target)
	if err != nil {
		utils.Failed(ctx, "组装getRankings查询参数失败!")
		return
	}

	contractAddress := common.HexToAddress(mc.cfg.Contract.Membership)
	msg := ethereum.CallMsg{
		To:   &contractAddress,
		Data: input,
	}

	result, err := mc.client.CallContract(context.Background(), msg, nil)
	if err != nil {
		utils.Failed(ctx, "调用合约getRankings查询方法失败!")
		return
	}

	output, err := mc.contractABI.Unpack("getRankings", result)
	if err != nil {
		utils.Failed(ctx, "getRankings查询结果解析失败!")
		return
	}
	utils.Success(ctx, output)
}

// function extractedMark(string memory mark) external view returns(bool);
func (mc *MembershipController) GetExtractedResult(ctx *gin.Context) {
	_mark, exist := ctx.GetQuery("mark")
	if !exist {
		utils.Failed(ctx, "GetExtractedResult get 请求参数解析失败!")
		return
	}
	input, err := mc.contractABI.Pack("transactionMark", _mark)
	if err != nil {
		utils.Failed(ctx, "组装extractedMark查询参数失败!")
		return
	}

	contractAddress := common.HexToAddress(mc.cfg.Contract.Membership)
	msg := ethereum.CallMsg{
		To:   &contractAddress,
		Data: input,
	}

	result, err := mc.client.CallContract(context.Background(), msg, nil)
	if err != nil {
		utils.Failed(ctx, "调用合约extractedMark查询方法失败!")
		return
	}

	output, err := mc.contractABI.Unpack("transactionMark", result)
	if err != nil {
		utils.Failed(ctx, "extractedMark查询结果解析失败!")
		return
	}
	utils.Success(ctx, output)
}

// function getMemberGrades(Target target,address member) external view returns(uint256);
func (mc *MembershipController) GetMemberGrades(ctx *gin.Context) {
	var param mode.Grades
	if err := json.NewDecoder(ctx.Request.Body).Decode(&param); err != nil {
		utils.Failed(ctx, "getMemberGrades参数解析失败")
		return
	}
	target, err := stringToUint8(param.Target)
	if err != nil {
		utils.Failed(ctx, "getMemberGrades函数string转uint8失败!")
	}

	input, err := mc.contractABI.Pack("extractedMark", target, common.HexToAddress(param.Member))
	if err != nil {
		utils.Failed(ctx, "组装getMemberGrades查询参数失败!")
		return
	}

	contractAddress := common.HexToAddress(mc.cfg.Contract.Membership)
	msg := ethereum.CallMsg{
		To:   &contractAddress,
		Data: input,
	}

	result, err := mc.client.CallContract(context.Background(), msg, nil)
	if err != nil {
		utils.Failed(ctx, "调用合约getMemberGrades查询方法失败!")
		return
	}

	output, err := mc.contractABI.Unpack("getMemberGrades", result)
	if err != nil {
		utils.Failed(ctx, "getMemberGrades查询结果解析失败!")
		return
	}
	utils.Success(ctx, output)
}

// function multiGetMemberGrades(Target target,address[] memory member) external view returns(Assemble[] memory);
func (mc *MembershipController) MultiGetMemberGrades(ctx *gin.Context) {
	var param mode.MultiGrades
	if err := json.NewDecoder(ctx.Request.Body).Decode(&param); err != nil {
		utils.Failed(ctx, "multiGetMemberGrades参数解析失败")
		return
	}
	target, err := stringToUint8(param.Target)
	if err != nil {
		utils.Failed(ctx, "multiGetMemberGrades函数string转uint8失败!")
	}
	members, err := convertToAddress(param.Members)
	if err != nil {
		utils.Failed(ctx, "multiGetMemberGrades函数string转address失败!")
	}

	input, err := mc.contractABI.Pack("multiGetMemberGrades", target, members)
	if err != nil {
		utils.Failed(ctx, "组装multiGetMemberGrades查询参数失败!")
		return
	}

	contractAddress := common.HexToAddress(mc.cfg.Contract.Membership)
	msg := ethereum.CallMsg{
		To:   &contractAddress,
		Data: input,
	}

	result, err := mc.client.CallContract(context.Background(), msg, nil)
	if err != nil {
		utils.Failed(ctx, "调用合约multiGetMemberGrades查询方法失败!")
		return
	}

	output, err := mc.contractABI.Unpack("multiGetMemberGrades", result)
	if err != nil {
		utils.Failed(ctx, "multiGetMemberGrades查询结果解析失败!")
		return
	}
	utils.Success(ctx, output)
}
