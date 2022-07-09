package utils

import (
	"log"
	"os"
)

type Config struct {
	AppMode            AppMode
	DatabaseUser       string
	DatabaseHost       string
	DatabasePassword   string
	BaseUrl            string
	ImageKitPublicKey  string
	ImageKitPrivateKey string
	ImageKitUrlPath    string
}

type AppMode string

const (
	Dev        AppMode = "DEV"
	Production         = "PROD"
	Orbital            = "ORBITAL"
)

var config Lazy[Config]

func getConfigOrThrow(config string, msg string) string {
	if value, present := os.LookupEnv(config); present {
		return value
	}
	log.Fatal(msg)
	return "" // won't reach here
}

func NewConfig() (*Config, error) {
	return config.LazyFallibleValue(func() (*Config, error) {
		appMode := getConfigOrThrow("APP_MODE", "Please set APP_MODE environment var to one in {DEV, PROV, ORBITAL}")
		return &Config{
			AppMode:            AppMode(appMode),
			DatabaseUser:       getConfigOrThrow("DB_USER", "Please set DB_USER environment var."),
			DatabaseHost:       getConfigOrThrow("DB_HOST", "Please set DB_HOST environment var."),
			DatabasePassword:   getConfigOrThrow("DB_PASSWORD", "Please set DB_PASSWORD environment var."),
			BaseUrl:            getConfigOrThrow("BASE_URL", "Please set BASE_URL environment var."),
			ImageKitPublicKey:  getConfigOrThrow("IMAGE_KIT_PUBLIC_KEY", "Please set IMAGE_KIT_PUBLIC_KEY environment var."),
			ImageKitPrivateKey: getConfigOrThrow("IMAGE_KIT_PRIVATE_KEY", "Please set IMAGE_KIT_PRIVATE_KEY environment var."),
			ImageKitUrlPath:    getConfigOrThrow("IMAGE_KIT_URL_PATH", "Please set IMAGE_KIT_URL_PATH environment var."),
		}, nil
	})
}
