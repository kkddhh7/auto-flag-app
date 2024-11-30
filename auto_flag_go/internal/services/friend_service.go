package services

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
	"errors"
)

type FriendService struct {
	Repo *repositories.FriendRepository
}

func NewFriendService(repo *repositories.FriendRepository) *FriendService {
	return &FriendService{Repo: repo}
}

func (s *FriendService) GetFollowings(userId string) ([]models.Friend, error) {
	followings, err := s.Repo.GetFollowings(userId)
	if err != nil {
		return nil, err
	}

	var friends []models.Friend
	for _, following := range followings {
		user, err := s.Repo.GetUserById(following.FolloweeID)
		if err != nil {
			return nil, err
		}
		friend := models.Friend{
			ID:           user.ID,
			Introduction: user.Introduction,
		}
		friends = append(friends, friend)
	}

	return friends, nil
}

func (s *FriendService) SearchFriend(userId string) (*models.Friend, error) {
	friend, err := s.Repo.GetUserById(userId)
	if err != nil || friend == nil {
		return nil, errors.New("친구를 찾을 수 없습니다")
	}

	f := &models.Friend{
		ID:           friend.ID,
		Introduction: friend.Introduction,
	}

	return f, nil
}

func (s *FriendService) AddFriend(following models.Following) error {
	err := s.Repo.AddFollowing(following)
	if err != nil {
		return errors.New("친구 추가에 실패했습니다")
	}
	return nil
}
