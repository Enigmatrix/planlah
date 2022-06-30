package services

import (
	storage2 "cloud.google.com/go/storage"
	"context"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"fmt"
	"github.com/codedius/imagekit-go"
	"github.com/google/uuid"
	errors2 "github.com/juju/errors"
	"io"
	lazy "planlah.sg/backend/utils"
	"time"
)

type ImageService interface {
	UploadGroupImage(imgReader io.Reader) (string, error)
	UploadUserImage(imgReader io.Reader) (string, error)
}

var firebaseStorageImageServiceInstance = lazy.New[FirebaseStorageImageService]()

func NewFirebaseStorageImageService(firebaseApp *firebase.App) (*FirebaseStorageImageService, error) {
	return firebaseStorageImageServiceInstance.FallibleValue(func() (*FirebaseStorageImageService, error) {
		firebaseStorage, err := firebaseApp.Storage(context.Background())
		if err != nil {
			return nil, errors2.Annotate(err, "cannot init firebase storage instance")
		}
		return &FirebaseStorageImageService{firebaseStorage: firebaseStorage}, nil
	})
}

type FirebaseStorageImageService struct {
	firebaseStorage *storage.Client
}

func (svc *FirebaseStorageImageService) uploadImage(imgReader io.Reader, path string) (string, error) {
	bucket, err := svc.firebaseStorage.DefaultBucket()
	if err != nil {
		return "", errors2.Annotate(err, "cannot get default bucket")
	}

	// 60 second timeout
	ctx := context.Background()
	ctx, cancel := context.WithTimeout(ctx, time.Minute)
	defer cancel()

	object := bucket.Object(path)
	objectWriter := object.NewWriter(ctx)

	if _, err = io.Copy(objectWriter, imgReader); err != nil {
		return "", errors2.Annotate(err, "copying objectWriter")
	}
	if err := objectWriter.Close(); err != nil {
		return "", errors2.Annotate(err, "closing objectWriter")
	}

	meta, err := object.Attrs(ctx)

	if err != nil {
		return "", errors2.Annotate(err, "object attrs")
	}

	// allow users to read the images
	if err := object.ACL().Set(ctx, storage2.AllUsers, storage2.RoleReader); err != nil {
		return "", errors2.Annotate(err, "object ACL.Set")
	}

	return meta.MediaLink, nil
}

func (svc *FirebaseStorageImageService) UploadGroupImage(imgReader io.Reader) (string, error) {
	return svc.uploadImage(imgReader, fmt.Sprintf("groups/%s", uuid.New().String()))
}

func (svc *FirebaseStorageImageService) UploadUserImage(imgReader io.Reader) (string, error) {
	return svc.uploadImage(imgReader, fmt.Sprintf("users/%s", uuid.New().String()))
}

func NewImageKitImageService(config *lazy.Config) (*ImageKitImageService, error) {
	opts := imagekit.Options{
		PublicKey:  config.ImageKitPublicKey,
		PrivateKey: config.ImageKitPrivateKey,
	}
	ik, err := imagekit.NewClient(&opts)
	if err != nil {
		return nil, errors2.Annotate(err, "cannot init ImageKit service")
	}
	return &ImageKitImageService{ImageKit: ik}, nil
}

type ImageKitImageService struct {
	ImageKit *imagekit.Client
}

func (svc *ImageKitImageService) uploadImage(reader io.Reader, folder string) (string, error) {
	bytes, err := io.ReadAll(reader)
	if err != nil {
		return "", errors2.Annotate(err, "reading image bytes")
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
		return "", errors2.Annotate(err, "uploading image to ImageKit")
	}
	return upr.URL, nil
}

func (svc *ImageKitImageService) UploadGroupImage(imgReader io.Reader) (string, error) {
	return svc.uploadImage(imgReader, "groups")
}

func (svc *ImageKitImageService) UploadUserImage(imgReader io.Reader) (string, error) {
	return svc.uploadImage(imgReader, "users")
}
