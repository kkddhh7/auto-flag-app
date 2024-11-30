package models

type User struct {
	ID           string `json:"id" db:"id"`
	Password     string `json:"password" db:"password"`
	Introduction string `json:"introduction" db:"introduction"`
}
