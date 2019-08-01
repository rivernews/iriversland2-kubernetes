# tf doc: https://www.terraform.io/docs/backends/types/pg.html
# tf doc env var: https://www.terraform.io/docs/configuration/variables.html#environment-variables
terraform init -backend-config="conn_str=${TF_BACKEND_POSTGRES_CONN_STR}"