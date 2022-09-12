package database

import (
	"context"
	"github.com/fastenhealth/fastenhealth-onprem/backend/pkg/models"
)

//go:generate mockgen -source=interface.go -destination=mock/mock_database.go
type DatabaseRepository interface {
	Close() error

	CreateUser(context.Context, *models.User) error
	GetUserByEmail(context.Context, string) (*models.User, error)
	GetCurrentUser() models.User

	UpsertResource(context.Context, models.ResourceFhir) error
	ListResources(context.Context, string, string) ([]models.ResourceFhir, error)
	//UpsertProfile(context.Context, *models.Profile) error
	//UpsertOrganziation(context.Context, *models.Organization) error

	CreateSource(context.Context, *models.Source) error
	GetSources(context.Context) ([]models.Source, error)
}
