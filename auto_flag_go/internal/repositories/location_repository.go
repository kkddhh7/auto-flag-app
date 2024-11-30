package repositories

import (
	"auto_flag_go/internal/models"

	"gorm.io/gorm"
)

type LocationRepository struct {
	db *gorm.DB
}

func NewLocationRepository(db *gorm.DB) *LocationRepository {
	return &LocationRepository{db: db}
}

func (r *LocationRepository) SaveLocation(location *models.Location) error {
	return r.db.Create(location).Error
}

func (r *LocationRepository) GetLocationsByUserID(userID string) ([]models.Location, error) {
	var locations []models.Location
	err := r.db.Where("ID = ?", userID).Find(&locations).Error
	return locations, err
}

func (lr *LocationRepository) UpdatePlace(id, registrationTime, title, address, memo string, latitude, longitude float64) error {
	return lr.db.Model(&models.Location{}).Where("id = ? AND registration_time = ?", id, registrationTime).
		Updates(map[string]interface{}{
			"title":     title,
			"address":   address,
			"memo":      memo,
			"latitude":  latitude,
			"longitude": longitude,
		}).Error
}

func (lr *LocationRepository) DeletePlace(id, registrationTime string) error {
	return lr.db.Where("id = ? AND registration_time = ?", id, registrationTime).Delete(&models.Location{}).Error
}
