# use s3
terraform init \
    -backend-config="access_key=${TF_VAR_aws_access_key}" \
    -backend-config="secret_key=${TF_VAR_aws_secret_key}" \
    -backend-config="region=${TF_BACKEND_region}"
