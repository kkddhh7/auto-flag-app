package repositories

import (
	"auto_flag_go/internal/models"

	"gorm.io/gorm"
)

type FriendRepository struct {
	DB *gorm.DB
}

func NewFriendRepository(db *gorm.DB) *FriendRepository {
	return &FriendRepository{DB: db}
}

func (r *FriendRepository) GetFollowings(userId string) ([]models.Following, error) {
	var followings []models.Following
	err := r.DB.Where("follower_id = ?", userId).Find(&followings).Error
	if err != nil {
		return nil, err
	}
	return followings, nil
}

func (r *FriendRepository) GetUserById(userId string) (*models.User, error) {
	var user models.User
	err := r.DB.Where("id = ?", userId).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *FriendRepository) AddFollowing(following models.Following) error {
	err := r.DB.Create(&following).Error
	if err != nil {
		return err
	}
	return nil
}
