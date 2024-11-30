package controllers

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/services"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

type SignupRequest struct {
	ID           string `json:"id" binding:"required"`
	PassWord     string `json:"password" binding:"required"`
	Introduction string `json:"introduction"`
}

func Signup(c *gin.Context) {
	var req SignupRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fmt.Println("Received Signup request: ID =", req.ID, "Password = ", req.PassWord, "Introduction = ", req.Introduction)

	user := models.User{
		ID:           req.ID,
		Password:     req.PassWord,
		Introduction: req.Introduction,
	}

	if err := services.CreateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User registered successfully"})
}
