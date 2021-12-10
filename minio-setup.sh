#! /bin/sh

mc alias set minio-tenant https://host.docker.internal:9000 minio minio123 --api S3v4
mc --insecure admin user add  minio-tenant ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY}
mc --insecure admin policy set minio-tenant readwrite user=${AWS_ACCESS_KEY_ID}

mc --insecure mb -p minio-tenant/my-bucket
