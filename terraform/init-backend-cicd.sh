# tf remote backend types doc: https://www.terraform.io/docs/backends/types/pg.html
# tf partial backend config: https://www.terraform.io/docs/backends/config.html
# tf doc env var: https://www.terraform.io/docs/configuration/variables.html#environment-variables

# use postgres
# terraform init -backend-config="conn_str=${TF_BACKEND_POSTGRES_CONN_STR}"

# use s3
terraform init \
    -backend-config="access_key=${TF_VAR_aws_access_key}" \
    -backend-config="secret_key=${TF_VAR_aws_secret_key}" \
    -backend-config="region=${TF_BACKEND_region}"
