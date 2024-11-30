package models

type Friend struct {
	ID           string `json:"id"`
	Introduction string `json:"introduction"`
}

type Following struct {
	FollowerID string `json:"followerId"`
	FolloweeID string `json:"followeeId"`
}
