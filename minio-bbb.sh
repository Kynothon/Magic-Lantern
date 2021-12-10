#! /bin/sh

mc alias set minio-tenant https://host.docker.internal:9000 minio minio123 --api S3v4
mc --insecure cp /tmp/big_buck_bunny_1080p_h264.mov minio-tenant/my-bucket/big_buck_bunny_1080p_h264.mov
