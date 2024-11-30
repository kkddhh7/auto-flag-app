package services

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
)

type UserService struct {
	repo *repositories.UserRepository
}

func NewUserService(repo *repositories.UserRepository) *UserService {
	return &UserService{repo: repo}
}

func (s *UserService) GetUser(id string) (*models.User, error) {
	return s.repo.GetUserByID(id)
}

func (s *UserService) UpdateUser(id, password, introduction string) error {
	user, err := s.repo.GetUserByID(id)
	if err != nil {
		return err
	}

	if password != "" {
		user.Password = password
	}
	if introduction != "" {
		user.Introduction = introduction
	}

	return s.repo.UpdateUser(user)
}
