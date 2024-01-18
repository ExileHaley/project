package utils

import (
	"encoding/json"
	"os"
)

type RPCConfig struct {
	URL      string `json:"url"`
	Timeout  int    `json:"timeout"`
	Gaslimit string `json:"gaslimit"`
	Multiple string `json:"multiple"`
}

type GinConfig struct {
	Port string `json:"port"`
	Mode string `json:"mode"`
}

type ContractConfig struct {
	Membership string `json:"membership"`
	PrivateKey string `json:"privateKey"`
}

type Config struct {
	RPC      RPCConfig      `json:"rpc"`
	GIN      GinConfig      `json:"gin"`
	Contract ContractConfig `json:"contract"`
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
