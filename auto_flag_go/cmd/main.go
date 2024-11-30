package main

import (
	"auto_flag_go/config"
	"auto_flag_go/internal/controllers"
	"auto_flag_go/internal/models"
	"auto_flag_go/internal/repositories"
	"auto_flag_go/internal/services"
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	config.InitDB()

	err := config.DB.AutoMigrate(&models.User{})
	if err != nil {
		log.Fatal("Failed to migrate User model:", err)
	}
	log.Println("User model migrated successfully")

	config.LoadConfig()

	authService := services.NewAuthService()
	AuthController := controllers.NewAuthController(authService)

	textService := services.NewTextService(config.GoogleVisionAPIKey)
	addressService := services.NewAddressService(config.ChatGPTAPIKey)
	coordinateService := services.NewCoordinateService(config.GoogleMapsAPIKey)
	ImageController := controllers.NewImageController(textService, addressService, coordinateService)

	locationRepo := repositories.NewLocationRepository(config.DB)
	locationService := services.NewLocationService(locationRepo)
	locationController := controllers.NewLocationController(locationService)

	listService := services.NewListService(locationRepo)
	listController := controllers.NewListController(listService)

	friendRepo := repositories.NewFriendRepository(config.DB)
	friendService := services.NewFriendService(friendRepo)
	friendController := controllers.NewFriendController(friendService)

	userRepo := repositories.NewUserRepository(config.DB)
	userService := services.NewUserService(userRepo)
	userController := controllers.NewUserController(userService)

	router := gin.Default()
	router.Use(cors.Default())
	router.Use(gin.Logger())
	router.Static("/uploads", "./uploads")

	router.POST("/signup", controllers.Signup)
	router.POST("/login", AuthController.Login)

	router.POST("/upload-image", ImageController.UploadImage)
	router.POST("/register-place", locationController.RegisterPlace)

	router.GET("/list", listController.GetUserLocations)
	router.PUT("/update/:id/:registrationTime", locationController.UpdatePlace)
	router.DELETE("/delete/:id/:registrationTime", locationController.DeletePlace)

	router.GET("/friends/:userId/followings", friendController.GetFollowings)
	router.GET("/friends/:userId/search", friendController.SearchFriend)
	router.POST("/friends/add", friendController.AddFriend)

	router.GET("/profile/:id", userController.GetProfile)
	router.PUT("/profile/:id", userController.UpdateProfile)

	router.Run(":3000")
}
