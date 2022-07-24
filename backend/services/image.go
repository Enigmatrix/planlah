package services

import (
	storage2 "cloud.google.com/go/storage"
	"context"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"fmt"
	"github.com/codedius/imagekit-go"
	"github.com/google/uuid"
	"github.com/juju/errors"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"io"
	lazy "planlah.sg/backend/utils"
	"time"
)

type ImageService interface {
	UploadGroupImage(imgReader io.Reader, size int64) (string, error)
	UploadUserImage(imgReader io.Reader, size int64) (string, error)
	UploadPostImage(imgReader io.Reader, size int64) (string, error)
	WithinLimits(size int64) bool
}

var firebaseStorageImageServiceInstance = lazy.NewLazy[FirebaseStorageImageService]()

func NewFirebaseStorageImageService(firebaseApp *firebase.App) (*FirebaseStorageImageService, error) {
	return firebaseStorageImageServiceInstance.LazyFallibleValue(func() (*FirebaseStorageImageService, error) {
		firebaseStorage, err := firebaseApp.Storage(context.Background())
		if err != nil {
			return nil, errors.Annotate(err, "cannot init firebase storage instance")
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
		return "", errors.Annotate(err, "cannot get default bucket")
	}

	// 60 second timeout
	ctx := context.Background()
	ctx, cancel := context.WithTimeout(ctx, time.Minute)
	defer cancel()

	object := bucket.Object(path)
	objectWriter := object.NewWriter(ctx)

	if _, err = io.Copy(objectWriter, imgReader); err != nil {
		return "", errors.Annotate(err, "copying objectWriter")
	}
	if err := objectWriter.Close(); err != nil {
		return "", errors.Annotate(err, "closing objectWriter")
	}

	meta, err := object.Attrs(ctx)

	if err != nil {
		return "", errors.Annotate(err, "object attrs")
	}

	// allow users to read the images
	if err := object.ACL().Set(ctx, storage2.AllUsers, storage2.RoleReader); err != nil {
		return "", errors.Annotate(err, "object ACL.Set")
	}

	return meta.MediaLink, nil
}

func (svc *FirebaseStorageImageService) UploadGroupImage(imgReader io.Reader, _ int64) (string, error) {
	return svc.uploadImage(imgReader, fmt.Sprintf("groups/%s", uuid.New().String()))
}

func (svc *FirebaseStorageImageService) UploadUserImage(imgReader io.Reader, _ int64) (string, error) {
	return svc.uploadImage(imgReader, fmt.Sprintf("users/%s", uuid.New().String()))
}

func (svc *FirebaseStorageImageService) UploadPostImage(imgReader io.Reader, _ int64) (string, error) {
	return svc.uploadImage(imgReader, fmt.Sprintf("posts/%s", uuid.New().String()))
}

func (svc *FirebaseStorageImageService) WithinLimits(_ int64) bool {
	return true
}

func NewImageKitImageService(config *lazy.Config) (*ImageKitImageService, error) {
	opts := imagekit.Options{
		PublicKey:  config.ImageKitPublicKey,
		PrivateKey: config.ImageKitPrivateKey,
	}
	ik, err := imagekit.NewClient(&opts)
	if err != nil {
		return nil, errors.Annotate(err, "cannot init ImageKit service")
	}
	return &ImageKitImageService{ImageKit: ik}, nil
}

type ImageKitImageService struct {
	ImageKit *imagekit.Client
}

func (svc *ImageKitImageService) uploadImage(reader io.Reader, folder string) (string, error) {
	bytes, err := io.ReadAll(reader)
	if err != nil {
		return "", errors.Annotate(err, "reading image bytes")
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
		return "", errors.Annotate(err, "uploading image to ImageKit")
	}
	return upr.URL, nil
}

func (svc *ImageKitImageService) UploadGroupImage(imgReader io.Reader, _ int64) (string, error) {
	return svc.uploadImage(imgReader, "groups")
}

func (svc *ImageKitImageService) UploadUserImage(imgReader io.Reader, _ int64) (string, error) {
	return svc.uploadImage(imgReader, "users")
}

func (svc *ImageKitImageService) UploadPostImage(imgReader io.Reader, _ int64) (string, error) {
	return svc.uploadImage(imgReader, "posts")
}

func (svc *ImageKitImageService) WithinLimits(_ int64) bool {
	return true
}

func NewMinioImageService(config *lazy.Config) (*MinioImageService, error) {
	client, err := minio.New(config.MinioInternalEndpoint, &minio.Options{
		Creds:  credentials.NewEnvMinio(),
		Secure: false,
	})
	if err != nil {
		return nil, errors.Annotate(err, "cannot init minio image service")
	}

	ctx := context.Background()

	buckets := []string{"groups", "users", "posts"}

	for _, bucket := range buckets {
		exists, err := client.BucketExists(ctx, bucket)
		if err != nil {
			return nil, errors.Annotatef(err, "check if bucket %s exists", bucket)
		}
		if !exists {
			err = client.MakeBucket(ctx, bucket, minio.MakeBucketOptions{})
			if err != nil {
				return nil, errors.Annotatef(err, "create bucket %s", bucket)
			}
			err = client.SetBucketPolicy(ctx, bucket, fmt.Sprintf(minioDownloadPolicyFormat, bucket, bucket))
			if err != nil {
				return nil, errors.Annotatef(err, "set bucket %s policy", bucket)
			}
		}
	}

	return &MinioImageService{Minio: client, externalUri: config.MinioExternalEndpoint}, nil
}

type MinioImageService struct {
	Minio       *minio.Client
	externalUri string
}

const minioUploadLimit = 10 << (10 * 2)
const minioDownloadPolicyFormat = `{
    "Statement": [{
        "Action": ["s3:GetBucketLocation"],
        "Effect": "Allow",
        "Principal": {
            "AWS": ["*"]
        },
        "Resource": ["arn:aws:s3:::%s"]
    }, {
        "Action": ["s3:GetObject"],
        "Effect": "Allow",
        "Principal": {
            "AWS": ["*"]
        },
        "Resource": ["arn:aws:s3:::%s/*"]
    }],
    "Version": "2012-10-17"
}`

func (svc *MinioImageService) urlFor(info minio.UploadInfo) string {
	url := fmt.Sprintf("http://%s/%s/%s", svc.externalUri, info.Bucket, info.Key)
	return url
}

func (svc *MinioImageService) uploadImage(reader io.Reader, size int64, folder string) (string, error) {
	ctx := context.Background()
	filename := uuid.New().String()

	info, err := svc.Minio.PutObject(ctx, folder, filename, reader, size, minio.PutObjectOptions{})
	if err != nil {
		return "", errors.Annotate(err, "uploading to minio")
	}
	return svc.urlFor(info), nil
}

func (svc *MinioImageService) UploadGroupImage(imgReader io.Reader, size int64) (string, error) {
	return svc.uploadImage(imgReader, size, "groups")
}

func (svc *MinioImageService) UploadUserImage(imgReader io.Reader, size int64) (string, error) {
	return svc.uploadImage(imgReader, size, "users")
}

func (svc *MinioImageService) UploadPostImage(imgReader io.Reader, size int64) (string, error) {
	return svc.uploadImage(imgReader, size, "posts")
}

func (svc *MinioImageService) WithinLimits(size int64) bool {
	return size < minioUploadLimit
}
