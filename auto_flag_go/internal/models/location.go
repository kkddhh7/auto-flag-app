package models

import "time"

type Location struct {
	ID               string
	Title            string
	Address          string
	Latitude         float64
	Longitude        float64
	Memo             string
	RegistrationTime time.Time
	ImagePath        string
}
