package controllers

import (
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type FriendController struct {
	Service *services.FriendService
}

func NewFriendController(service *services.FriendService) *FriendController {
	return &FriendController{Service: service}
}

func (c *FriendController) GetFollowings(ctx *gin.Context) {
	userId := ctx.Param("userId")
	followings, err := c.Service.GetFollowings(userId)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "팔로잉 목록을 가져오지 못했습니다"})
		return
	}
	ctx.JSON(http.StatusOK, followings)
}

func (c *FriendController) SearchFriend(ctx *gin.Context) {
	userId := ctx.Param("userId")
	friend, err := c.Service.SearchFriend(userId)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "친구를 찾을 수 없습니다"})
		return
	}
	ctx.JSON(http.StatusOK, friend)
}

func (c *FriendController) AddFriend(ctx *gin.Context) {
	var following models.Following
	if err := ctx.ShouldBindJSON(&following); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "유효하지 않은 요청입니다"})
		return
	}

	if err := c.Service.AddFriend(following); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "친구 추가에 실패했습니다"})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "친구 추가 성공"})
}
