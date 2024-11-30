package controllers

import (
	"auto_flag_go/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type ListController struct {
	listService *services.ListService
}

func NewListController(listService *services.ListService) *ListController {
	return &ListController{
		listService: listService,
	}
}

func (c *ListController) GetUserLocations(ctx *gin.Context) {
	userID := ctx.Query("ID")
	if userID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID is required"})
		return
	}

	locations, err := c.listService.GetLocationsByUserID(userID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve locations"})
		return
	}

	ctx.JSON(http.StatusOK, locations)
}
