package services

import (
	"context"
	"errors"
	firebase "firebase.google.com/go/v4"
	"fmt"
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
			return nil, errors.New(fmt.Sprintf("cannot init firebase app: %v", err))
		}
		return firebaseApp, nil
	})
}
