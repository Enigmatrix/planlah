package services

import (
	"context"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	lazy "planlah.sg/backend/utils"
)

type AuthService struct {
	firebaseApp  *firebase.App
	firebaseAuth *auth.Client
}

var instance = lazy.New[AuthService]()

// NewAuthService creates a new AuthService
func NewAuthService() (*AuthService, error) {
	return instance.FallibleValue(func() (*AuthService, error) {
		ctx := context.Background()
		firebaseApp, err := firebase.NewApp(ctx, nil)
		if err != nil {
			return nil, err
		}
		firebaseAuth, err := firebaseApp.Auth(context.Background())
		if err != nil {
			return nil, err
		}
		return &AuthService{firebaseApp: firebaseApp, firebaseAuth: firebaseAuth}, nil
	})
}

// Verify the Firebase Token, and return the Authenticated User's UID
func (authSvc *AuthService) Verify(firebaseToken string) (*string, error) {
	verifiedToken, err := authSvc.firebaseAuth.VerifyIDToken(context.Background(), firebaseToken)
	if err != nil {
		return nil, err
	}
	return &verifiedToken.UID, nil
}
