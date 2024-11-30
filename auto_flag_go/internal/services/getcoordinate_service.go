package services

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

type CoordinateService struct {
	apiKey string
}

func NewCoordinateService(apiKey string) *CoordinateService {
	return &CoordinateService{apiKey: apiKey}
}

func (cs *CoordinateService) GetCoordinates(address string) (float64, float64, error) {
	encodedAddress := url.QueryEscape(address)
	requestURL := fmt.Sprintf("https://maps.googleapis.com/maps/api/geocode/json?address=%s&key=%s", encodedAddress, cs.apiKey)

	resp, err := http.Get(requestURL)
	if err != nil {
		return 0, 0, fmt.Errorf("Geocoding API 호출 오류: %v", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return 0, 0, fmt.Errorf("응답 디코딩 오류: %v", err)
	}

	results, ok := result["results"].([]interface{})
	if !ok || len(results) == 0 {
		return 0, 0, fmt.Errorf("주소를 찾을 수 없습니다.")
	}

	location := results[0].(map[string]interface{})["geometry"].(map[string]interface{})["location"].(map[string]interface{})
	latitude := location["lat"].(float64)
	longitude := location["lng"].(float64)

	fmt.Println("latitude: ", latitude)
	fmt.Println("longitude: ", longitude)

	return latitude, longitude, nil
}
