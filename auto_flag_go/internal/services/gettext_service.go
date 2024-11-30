package services

import (
	"bytes"
	"context"
	"fmt"
	"io/ioutil"

	vision "cloud.google.com/go/vision/apiv1"
	"google.golang.org/api/option"
)

type TextService struct {
	client *vision.ImageAnnotatorClient
}

func NewTextService(serviceAccountFilePath string) *TextService {
	ctx := context.Background()

	client, err := vision.NewImageAnnotatorClient(ctx, option.WithCredentialsFile(serviceAccountFilePath))
	if err != nil {
		fmt.Println("Google Vision API 클라이언트 생성 실패:", err)
		return nil
	}
	return &TextService{client: client}
}

func (ts *TextService) DetectedText(filePath string) (string, error) {
	ctx := context.Background()
	client := ts.client

	fileBytes, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "", err
	}

	image, err := vision.NewImageFromReader(bytes.NewReader(fileBytes))
	if err != nil {
		return "", err
	}

	annotations, err := client.DetectTexts(ctx, image, nil, 1)
	if err != nil {
		return "", fmt.Errorf("텍스트를 감지하지 못했습니다. 오류: %v", err)
	}
	if len(annotations) == 0 {
		return "", fmt.Errorf("텍스트를 감지하지 못했습니다.")
	}

	detectedText := annotations[0].Description

	fmt.Println("detected text:", detectedText)

	return detectedText, nil
}
