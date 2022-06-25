package services

import (
	storage2 "cloud.google.com/go/storage"
	"context"
	"errors"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"fmt"
	"github.com/google/uuid"
	"io"
	"log"
	lazy "planlah.sg/backend/utils"
	"time"
)

type ImageService interface {
	UploadGroupImage(imgReader io.Reader) string
	UploadUserImage(imgReader io.Reader) string
}

var firebaseStorageImageServiceInstance = lazy.New[FirebaseStorageImageService]()

func NewFirebaseStorageImageService(firebaseApp *firebase.App) (*FirebaseStorageImageService, error) {
	return firebaseStorageImageServiceInstance.FallibleValue(func() (*FirebaseStorageImageService, error) {
		firebaseStorage, err := firebaseApp.Storage(context.Background())
		if err != nil {
			return nil, errors.New(fmt.Sprintf("cannot init firebase storage instance: %v", err))
		}
		return &FirebaseStorageImageService{firebaseStorage: firebaseStorage}, nil
	})
}

type FirebaseStorageImageService struct {
	firebaseStorage *storage.Client
}

func (svc *FirebaseStorageImageService) uploadImage(imgReader io.Reader, path string) string {
	bucket, err := svc.firebaseStorage.DefaultBucket()
	if err != nil {
		log.Fatalf("bucket error: %v", err)
	}

	// 60 second timeout
	ctx := context.Background()
	ctx, cancel := context.WithTimeout(ctx, time.Minute)
	defer cancel()

	object := bucket.Object(path)
	objectWriter := object.NewWriter(ctx)

	if _, err = io.Copy(objectWriter, imgReader); err != nil {
		log.Fatalf("objectWriter io.Copy: %v", err)
	}
	if err := objectWriter.Close(); err != nil {
		log.Fatalf("objectWriter close: %v", err)
	}

	meta, err := object.Attrs(ctx)

	if err != nil {
		log.Fatalf("object meta: %v", err)
	}

	// allow users to read the images
	if err := object.ACL().Set(ctx, storage2.AllUsers, storage2.RoleReader); err != nil {
		log.Fatalf("object ACL.Set: %v", err)
	}

	return meta.MediaLink
}

func (svc *FirebaseStorageImageService) UploadGroupImage(imgReader io.Reader) string {
	return svc.uploadImage(imgReader, fmt.Sprintf("groups/%s", uuid.New().String()))
}

func (svc *FirebaseStorageImageService) UploadUserImage(imgReader io.Reader) string {
	return svc.uploadImage(imgReader, fmt.Sprintf("users/%s", uuid.New().String()))
}
