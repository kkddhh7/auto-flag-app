package services

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
	"log"
)

type LocationService struct {
	locationRepo *repositories.LocationRepository
}

func NewLocationService(locationRepo *repositories.LocationRepository) *LocationService {
	return &LocationService{locationRepo: locationRepo}
}

func (ls *LocationService) SaveLocation(location *models.Location) error {
	if err := ls.locationRepo.SaveLocation(location); err != nil {
		log.Println("Error saving location:", err)
		return err
	}
	return nil
}

func (ls *LocationService) UpdatePlace(id, registrationTime, title, address, memo string, latitude, longitude float64) error {
	return ls.locationRepo.UpdatePlace(id, registrationTime, title, address, memo, latitude, longitude)
}

func (ls *LocationService) DeletePlace(id, registrationTime string) error {
	return ls.locationRepo.DeletePlace(id, registrationTime)
}
