package repositories

import (
	"auto_flag_go/config"
	"auto_flag_go/internal/models"
	"fmt"
	"log"

	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

func SaveUser(user models.User) error {
	query := "INSERT INTO users (id, password, introduction) VALUES (?, ?, ?)"
	result := config.DB.Exec(query, user.ID, user.Password, user.Introduction)
	return result.Error
}

func GetUserByID(id string) (*models.User, error) {
	var user models.User

	result := config.DB.Where("id = ?", id).First(&user)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("user not found")
		}
		log.Println("Error fetching user by ID:", result.Error)
		return nil, result.Error
	}

	return &user, nil
}

func (ur *UserRepository) GetUserByID(id string) (*models.User, error) {
	var user models.User
	result := ur.db.Where("id = ?", id).First(&user)
	if result.Error != nil {
		return nil, result.Error
	}
	return &user, nil
}

func (ur *UserRepository) UpdateUser(user *models.User) error {
	return ur.db.Save(user).Error
}
