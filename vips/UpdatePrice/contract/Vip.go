// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package vip

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// VipMetaData contains all meta data concerning the Vip contract.
var VipMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[],\"name\":\"tokenPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_price\",\"type\":\"uint256\"}],\"name\":\"updatePrice\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// VipABI is the input ABI used to generate the binding from.
// Deprecated: Use VipMetaData.ABI instead.
var VipABI = VipMetaData.ABI

// Vip is an auto generated Go binding around an Ethereum contract.
type Vip struct {
	VipCaller     // Read-only binding to the contract
	VipTransactor // Write-only binding to the contract
	VipFilterer   // Log filterer for contract events
}

// VipCaller is an auto generated read-only Go binding around an Ethereum contract.
type VipCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VipTransactor is an auto generated write-only Go binding around an Ethereum contract.
type VipTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VipFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type VipFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VipSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type VipSession struct {
	Contract     *Vip              // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// VipCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type VipCallerSession struct {
	Contract *VipCaller    // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// VipTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type VipTransactorSession struct {
	Contract     *VipTransactor    // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// VipRaw is an auto generated low-level Go binding around an Ethereum contract.
type VipRaw struct {
	Contract *Vip // Generic contract binding to access the raw methods on
}

// VipCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type VipCallerRaw struct {
	Contract *VipCaller // Generic read-only contract binding to access the raw methods on
}

// VipTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type VipTransactorRaw struct {
	Contract *VipTransactor // Generic write-only contract binding to access the raw methods on
}

// NewVip creates a new instance of Vip, bound to a specific deployed contract.
func NewVip(address common.Address, backend bind.ContractBackend) (*Vip, error) {
	contract, err := bindVip(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Vip{VipCaller: VipCaller{contract: contract}, VipTransactor: VipTransactor{contract: contract}, VipFilterer: VipFilterer{contract: contract}}, nil
}

// NewVipCaller creates a new read-only instance of Vip, bound to a specific deployed contract.
func NewVipCaller(address common.Address, caller bind.ContractCaller) (*VipCaller, error) {
	contract, err := bindVip(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &VipCaller{contract: contract}, nil
}

// NewVipTransactor creates a new write-only instance of Vip, bound to a specific deployed contract.
func NewVipTransactor(address common.Address, transactor bind.ContractTransactor) (*VipTransactor, error) {
	contract, err := bindVip(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &VipTransactor{contract: contract}, nil
}

// NewVipFilterer creates a new log filterer instance of Vip, bound to a specific deployed contract.
func NewVipFilterer(address common.Address, filterer bind.ContractFilterer) (*VipFilterer, error) {
	contract, err := bindVip(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &VipFilterer{contract: contract}, nil
}

// bindVip binds a generic wrapper to an already deployed contract.
func bindVip(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := VipMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Vip *VipRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Vip.Contract.VipCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Vip *VipRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Vip.Contract.VipTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Vip *VipRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Vip.Contract.VipTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Vip *VipCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Vip.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Vip *VipTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Vip.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Vip *VipTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Vip.Contract.contract.Transact(opts, method, params...)
}

// TokenPrice is a free data retrieval call binding the contract method 0x7ff9b596.
//
// Solidity: function tokenPrice() view returns(uint256)
func (_Vip *VipCaller) TokenPrice(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Vip.contract.Call(opts, &out, "tokenPrice")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TokenPrice is a free data retrieval call binding the contract method 0x7ff9b596.
//
// Solidity: function tokenPrice() view returns(uint256)
func (_Vip *VipSession) TokenPrice() (*big.Int, error) {
	return _Vip.Contract.TokenPrice(&_Vip.CallOpts)
}

// TokenPrice is a free data retrieval call binding the contract method 0x7ff9b596.
//
// Solidity: function tokenPrice() view returns(uint256)
func (_Vip *VipCallerSession) TokenPrice() (*big.Int, error) {
	return _Vip.Contract.TokenPrice(&_Vip.CallOpts)
}

// UpdatePrice is a paid mutator transaction binding the contract method 0x8d6cc56d.
//
// Solidity: function updatePrice(uint256 _price) returns()
func (_Vip *VipTransactor) UpdatePrice(opts *bind.TransactOpts, _price *big.Int) (*types.Transaction, error) {
	return _Vip.contract.Transact(opts, "updatePrice", _price)
}

// UpdatePrice is a paid mutator transaction binding the contract method 0x8d6cc56d.
//
// Solidity: function updatePrice(uint256 _price) returns()
func (_Vip *VipSession) UpdatePrice(_price *big.Int) (*types.Transaction, error) {
	return _Vip.Contract.UpdatePrice(&_Vip.TransactOpts, _price)
}

// UpdatePrice is a paid mutator transaction binding the contract method 0x8d6cc56d.
//
// Solidity: function updatePrice(uint256 _price) returns()
func (_Vip *VipTransactorSession) UpdatePrice(_price *big.Int) (*types.Transaction, error) {
	return _Vip.Contract.UpdatePrice(&_Vip.TransactOpts, _price)
}
