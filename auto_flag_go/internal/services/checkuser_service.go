package services

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
	"errors"
)

func CheckUserCredentials(id, password string) (*models.User, error) {
	user, err := repositories.GetUserByID(id)
	if err != nil {
		return nil, err
	}

	if user.Password != password {
		return nil, errors.New("invalid credentials")
	}

	return user, nil
}
