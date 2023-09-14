package utils

import (
	"encoding/json"
	"os"
)

type MysqlConfig struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	User     string `json:"user"`
	Password string `json:"password"`
	Database string `json:"database"`
}

type RPCConfig struct {
	URL             string `json:"url"`
	Timeout         int    `json:"timeout"`
	ContractAddress string `json:"contractAddress"`
}

type Config struct {
	MySQL MysqlConfig `json:"mysql"`
	RPC   RPCConfig   `json:"rpc"`
}

func ParseConfig(dir string) (*Config, error) {

	var cfg *Config
	file, err := os.Open(dir)
	if err != nil {
		return nil, err
	}
	if err = json.NewDecoder(file).Decode(&cfg); err != nil {
		return nil, err
	}
	return cfg, err
}
