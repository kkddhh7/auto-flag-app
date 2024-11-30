package controllers

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/services"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type LocationController struct {
	locationService *services.LocationService
}

func NewLocationController(locationService *services.LocationService) *LocationController {
	return &LocationController{locationService: locationService}
}

func (lc *LocationController) RegisterPlace(c *gin.Context) {
	id := c.PostForm("id")
	title := c.PostForm("title")
	address := c.PostForm("address")
	latitudeStr := c.PostForm("latitude")
	longitudeStr := c.PostForm("longitude")
	memo := c.PostForm("memo")
	registrationTime := c.PostForm("registration_time")

	log.Println("데이터 수신:", id, title, address, latitudeStr, longitudeStr, memo, registrationTime)

	latitude, err := strconv.ParseFloat(latitudeStr, 64)
	if err != nil {
		log.Println("위도 값 오류:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "위도 값이 유효하지 않습니다."})
		return
	}

	longitude, err := strconv.ParseFloat(longitudeStr, 64)
	if err != nil {
		log.Println("경도 값 오류:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "경도 값이 유효하지 않습니다."})
		return
	}

	file, err := c.FormFile("image")
	if err != nil {
		log.Println("이미지 파일 오류:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "이미지 파일이 필요합니다."})
		return
	}

	fileName := file.Filename
	filePath := filepath.Join("./uploads", fileName)

	if _, err := os.Stat("./uploads"); os.IsNotExist(err) {
		os.Mkdir("./uploads", os.ModePerm)
	}

	if err := c.SaveUploadedFile(file, filePath); err != nil {
		log.Println("이미지 저장 오류:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "이미지 저장 실패"})
		return
	}

	parsedTime, err := time.Parse(time.RFC3339, registrationTime)
	if err != nil {
		log.Println("등록 시간 형식 오류:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "등록 시간 형식 오류"})
		return
	}

	location := models.Location{
		ID:               id,
		Title:            title,
		Address:          address,
		Latitude:         latitude,
		Longitude:        longitude,
		Memo:             memo,
		RegistrationTime: parsedTime,
		ImagePath:        filePath,
	}

	if err := lc.locationService.SaveLocation(&location); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "데이터베이스 저장 실패"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "장소가 성공적으로 등록되었습니다."})
}

func (lc *LocationController) UpdatePlace(c *gin.Context) {
	id := c.Param("id")
	registrationTime := c.Param("registrationTime")

	var request struct {
		Title     string  `json:"title"`
		Address   string  `json:"address"`
		Memo      string  `json:"memo"`
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	err := lc.locationService.UpdatePlace(id, registrationTime, request.Title, request.Address, request.Memo, request.Latitude, request.Longitude)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update place"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Place updated successfully"})
}

func (lc *LocationController) DeletePlace(c *gin.Context) {
	id := c.Param("id")
	registrationTime := c.Param("registrationTime")

	err := lc.locationService.DeletePlace(id, registrationTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete place"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Place deleted successfully"})
}
