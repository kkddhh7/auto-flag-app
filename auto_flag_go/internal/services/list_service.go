package services

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
	"log"
)

type ListService struct {
	locationRepo *repositories.LocationRepository
}

func NewListService(locationRepo *repositories.LocationRepository) *ListService {
	return &ListService{locationRepo: locationRepo}
}

func (ls *ListService) GetLocationsByUserID(userID string) ([]models.Location, error) {
	locations, err := ls.locationRepo.GetLocationsByUserID(userID)
	if err != nil {
		log.Println("Error retrieving locations:", err)
		return nil, err
	}
	return locations, nil
}
