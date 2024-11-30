package controllers

import (
	"auto_flag_go/internal/services"
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

type ImageController struct {
	textService       *services.TextService
	addressService    *services.AddressService
	coordinateService *services.CoordinateService
}

func NewImageController(ts *services.TextService, as *services.AddressService, cs *services.CoordinateService) *ImageController {
	return &ImageController{
		textService:       ts,
		addressService:    as,
		coordinateService: cs,
	}
}

func (ic *ImageController) UploadImage(c *gin.Context) {
	fmt.Println("UploadImage 시작")

	file, _ := c.FormFile("image")
	fileName := file.Filename
	filePath := filepath.Join("./uploads", fileName)

	if _, err := os.Stat("./uploads"); os.IsNotExist(err) {
		if err := os.Mkdir("./uploads", os.ModePerm); err != nil {
			fmt.Println("업로드 디렉토리 생성 실패:", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "디렉토리 생성 실패"})
			return
		}
	}

	fmt.Println("파일명:", fileName)
	fmt.Println("파일 저장 경로:", filePath)

	if err := c.SaveUploadedFile(file, filePath); err != nil {
		fmt.Println("파일 저장 실패:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "파일 저장 실패"})
		return
	}

	detectedText, err := ic.textService.DetectedText(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "텍스트 인식 실패"})
		return
	}

	address, err := ic.addressService.ExtractAddress(detectedText)
	if err != nil {
		fmt.Println("주소 추출 실패:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "주소 추출 실패"})
		return
	}

	latitude, longitude, err := ic.coordinateService.GetCoordinates(address)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "위도 경도 조회 실패"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"address":   address,
		"latitude":  latitude,
		"longitude": longitude,
	})

	fmt.Println("server to app")
	fmt.Println("address: ", address)
	fmt.Println("latitude: ", latitude)
	fmt.Println("longitude: ", longitude)

	if err := os.Remove(filePath); err != nil {
		fmt.Println("파일 삭제 실패:", err)
	} else {
		fmt.Println("파일 삭제 성공:", filePath)
	}
}
