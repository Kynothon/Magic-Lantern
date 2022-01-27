#! /bin/sh

mc alias set ${MINIO_TENANT} https://host.docker.internal:9000 ${MINIO_CONSOLE_USERNAME} ${MINIO_CONSOLE_PASSWORD} --api S3v4
mc --insecure cp /tmp/big_buck_bunny_1080p_h264.mov ${MINIO_TENANT}/my-bucket/big_buck_bunny_1080p_h264.mov
