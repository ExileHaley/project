package controller

import (
	"context"
	"encoding/hex"
	"fmt"
	"strconv"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
)

func stringToUint8(str string) (uint8, error) {
	i, err := strconv.Atoi(str)
	if err != nil {
		return 0, err
	}

	// Check if the integer is within the uint8 range
	if i < 0 || i > 255 {
		return 0, fmt.Errorf("value out of uint8 range")
	}

	// Convert the integer to uint8
	return uint8(i), nil
}

func convertToAddress(params []string) ([]common.Address, error) {
	var users []common.Address
	for _, param := range params {
		// Remove the "0x" prefix from the address string
		addressString := strings.TrimPrefix(param, "0x")

		var user common.Address
		if _, err := hex.DecodeString(addressString); err != nil {
			return nil, err
		}

		user.SetBytes(common.HexToAddress(param).Bytes())
		users = append(users, user)
	}
	return users, nil
}

func (mc *MembershipController) EstimateGasLimit(contract string, input []byte) (uint64, error) {
	contractAddress := common.HexToAddress(contract)
	gasLimit, err := mc.client.EstimateGas(context.Background(), ethereum.CallMsg{
		To:   &contractAddress,
		Data: input,
	})
	if err != nil {
		return 0, err
	}
	return gasLimit, nil
}
