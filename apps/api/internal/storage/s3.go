package storage

import (
	"context"
	"fmt"
	"io"
	"strings"

	"creative-gym/apps/api/internal/config"
	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type Object struct {
	Body          io.ReadCloser
	ContentType   string
	ContentLength int64
}

type S3ObjectStore struct {
	client *s3.Client
	bucket string
}

func NewS3ObjectStore(ctx context.Context, cfg config.S3Config) (*S3ObjectStore, error) {
	awsCfg, err := awsconfig.LoadDefaultConfig(
		ctx,
		awsconfig.WithRegion(cfg.Region),
		awsconfig.WithCredentialsProvider(
			credentials.NewStaticCredentialsProvider(cfg.AccessKey, cfg.SecretKey, ""),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("load s3 config: %w", err)
	}

	endpoint := cfg.Endpoint
	if !strings.HasPrefix(endpoint, "http://") && !strings.HasPrefix(endpoint, "https://") {
		endpoint = "https://" + endpoint
	}

	client := s3.NewFromConfig(awsCfg, func(options *s3.Options) {
		options.BaseEndpoint = aws.String(endpoint)
		options.UsePathStyle = true
	})

	return &S3ObjectStore{
		client: client,
		bucket: cfg.Bucket,
	}, nil
}

func (s *S3ObjectStore) Bucket() string {
	return s.bucket
}

func (s *S3ObjectStore) Put(ctx context.Context, key string, body io.Reader, contentType string, byteSize int64) error {
	_, err := s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:        aws.String(s.bucket),
		Key:           aws.String(key),
		Body:          body,
		ContentLength: aws.Int64(byteSize),
		ContentType:   aws.String(contentType),
	})
	if err != nil {
		return fmt.Errorf("put s3 object: %w", err)
	}

	return nil
}

func (s *S3ObjectStore) Get(ctx context.Context, bucket string, key string) (Object, error) {
	output, err := s.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return Object{}, fmt.Errorf("get s3 object: %w", err)
	}

	return Object{
		Body:          output.Body,
		ContentType:   aws.ToString(output.ContentType),
		ContentLength: aws.ToInt64(output.ContentLength),
	}, nil
}

func (s *S3ObjectStore) Delete(ctx context.Context, bucket string, key string) error {
	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("delete s3 object: %w", err)
	}

	return nil
}
