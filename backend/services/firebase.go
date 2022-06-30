package services

import (
	"context"
	firebase "firebase.google.com/go/v4"
	errors2 "github.com/juju/errors"
	lazy "planlah.sg/backend/utils"
)

var firebaseAppInstance = lazy.New[firebase.App]()

func NewFirebaseApp() (*firebase.App, error) {
	return firebaseAppInstance.FallibleValue(func() (*firebase.App, error) {
		ctx := context.Background()
		firebaseApp, err := firebase.NewApp(ctx, &firebase.Config{
			StorageBucket: "planlah.appspot.com",
		})
		if err != nil {
			return nil, errors2.Annotate(err, "cannot init firebase app")
		}
		return firebaseApp, nil
	})
}
