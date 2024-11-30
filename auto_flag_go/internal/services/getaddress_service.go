package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

type AddressService struct {
	apiKey string
}

func NewAddressService(apiKey string) *AddressService {
	return &AddressService{apiKey: apiKey}
}

func (as *AddressService) ExtractAddress(detectedText string) (string, error) {

	requestBody, _ := json.Marshal(map[string]interface{}{
		"model": "gpt-3.5-turbo",
		"messages": []map[string]interface{}{
			{
				"role":    "system",
				"content": "You are a helpful assistant.",
			},
			{
				"role":    "user",
				"content": fmt.Sprintf("다음 텍스트에서 주소만을 추출해 주세요: %s", detectedText),
			},
		},
	})

	req, err := http.NewRequest("POST", "https://api.openai.com/v1/chat/completions", bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("요청 생성 오류: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+as.apiKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API 호출 오류: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return "", fmt.Errorf("API 호출 실패: 상태 코드 %d, 응답 본문: %s", resp.StatusCode, body)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("응답 파싱 오류: %v", err)
	}

	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("응답에서 'choices' 필드를 찾을 수 없거나 빈 배열입니다.")
	}

	address, ok := choices[0].(map[string]interface{})["message"].(map[string]interface{})["content"].(string)
	if !ok {
		return "", fmt.Errorf("응답에서 주소를 추출할 수 없습니다.")
	}

	fmt.Println("extracted address:", address)

	return address, nil
}
