package config

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"github.com/joho/godotenv"
)

var (
	DB                 *gorm.DB
	GoogleVisionAPIKey string
	ChatGPTAPIKey      string
	GoogleMapsAPIKey   string
)

func InitDB() {
	err := godotenv.Load()
	if err != nil {
		log.Println("Error loading .env file")
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to databse:", err)
	}

	DB = db
	log.Println("Database connection established")
}

func LoadConfig() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	googleCredentials := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if googleCredentials == "" {
		log.Fatal("서비스 계정 파일 경로가 설정되지 않았습니다.")
	}

	fmt.Println("Google Vision API 서비스 계정 파일 경로:", googleCredentials)

	ChatGPTAPIKey = os.Getenv("CHATGPT_API_KEY")
	GoogleMapsAPIKey = os.Getenv("GOOGLE_MAPS_API_KEY")

	if ChatGPTAPIKey == "" || GoogleMapsAPIKey == "" {
		log.Fatal("API keys are not set in environment variables")
	}

	fmt.Println("ChatGPTAPIKey:", ChatGPTAPIKey)
	fmt.Println("GoogleMapsAPIKey:", GoogleMapsAPIKey)

	fmt.Println("Configuration loaded successfully")
}
