#! /bin/sh

mc alias set ${MINIO_TENANT} https://host.docker.internal:9000 ${MINIO_CONSOLE_USERNAME} ${MINIO_CONSOLE_PASSWORD}  --api S3v4
mc --insecure admin user add ${MINIO_TENANT} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY}
mc --insecure admin policy set ${MINIO_TENANT} readwrite user=${AWS_ACCESS_KEY_ID}

mc --insecure mb -p ${MINIO_TENANT}/my-bucket
mc --insecure policy set public ${MINIO_TENANT}/my-bucket
