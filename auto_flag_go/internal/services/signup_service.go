package services

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
)

func CreateUser(user models.User) error {
	return repositories.SaveUser(user)
}
