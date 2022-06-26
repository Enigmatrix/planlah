package services

import (
	storage2 "cloud.google.com/go/storage"
	"context"
	"errors"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"fmt"
	"github.com/codedius/imagekit-go"
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

func NewImageKitImageService(config *lazy.Config) (*ImageKitImageService, error) {
	opts := imagekit.Options{
		PublicKey:  config.ImageKitPublicKey,
		PrivateKey: config.ImageKitPrivateKey,
	}
	ik, err := imagekit.NewClient(&opts)
	if err != nil {
		return nil, fmt.Errorf("cannot init image kit service: %v", err)
	}
	return &ImageKitImageService{ImageKit: ik}, nil
}

type ImageKitImageService struct {
	ImageKit *imagekit.Client
}

func (svc *ImageKitImageService) uploadImage(reader io.Reader, folder string) string {
	bytes, err := io.ReadAll(reader)
	if err != nil {
		log.Fatalf("error reading image bytes: %v", err)
	}
	req := imagekit.UploadRequest{
		File:              bytes,
		FileName:          uuid.New().String(),
		UseUniqueFileName: true,
		Folder:            folder,
		IsPrivateFile:     false,
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()

	upr, err := svc.ImageKit.Upload.ServerUpload(ctx, &req)
	if err != nil {
		log.Fatalf("error uploading image (%s): %v", folder, err)
	}
	return upr.URL
}

func (svc *ImageKitImageService) UploadGroupImage(imgReader io.Reader) string {
	return svc.uploadImage(imgReader, "groups")
}

func (svc *ImageKitImageService) UploadUserImage(imgReader io.Reader) string {
	return svc.uploadImage(imgReader, "users")
}
