# docker awscli s3
# https://docs.aws.amazon.com/cli/latest/reference/s3/index.html#use-of-exclude-and-include-filters

set -e

# Load credentials from backend-credentials.tfvars if they aren't already set
CREDENTIALS_FILE="backend-credentials.tfvars"
if [[ -f "$CREDENTIALS_FILE" ]]; then
    echo "INFO: Loading credentials from $CREDENTIALS_FILE"
    # Use grep/sed to handle spaces and quotes
    FILE_ACCESS_KEY=$(grep "access_key" "$CREDENTIALS_FILE" | sed -E 's/.*=[[:space:]]*"(.*)"/\1/') || true
    FILE_SECRET_KEY=$(grep "secret_key" "$CREDENTIALS_FILE" | sed -E 's/.*=[[:space:]]*"(.*)"/\1/') || true
    FILE_REGION=$(grep "region" "$CREDENTIALS_FILE" | sed -E 's/.*=[[:space:]]*"(.*)"/\1/') || true

    [[ -n "$FILE_ACCESS_KEY" ]] && export TF_VAR_aws_access_key=${TF_VAR_aws_access_key:-$FILE_ACCESS_KEY}
    [[ -n "$FILE_SECRET_KEY" ]] && export TF_VAR_aws_secret_key=${TF_VAR_aws_secret_key:-$FILE_SECRET_KEY}
    [[ -n "$FILE_REGION" ]] && export TF_VAR_aws_region=${TF_VAR_aws_region:-$FILE_REGION}
fi

# TODO: make this script customizable by supporting 1) only remove /terraform resources 2) remove all (entire cluster)
if [[ -z "$TF_VAR_aws_access_key" || -z "$TF_VAR_aws_secret_key" || -z "$TF_VAR_aws_region" ]]; then
    echo "One or more aws credentials are not provided, try to use local config"
    docker run --rm -ti -v ~/.aws:/root/.aws amazon/aws-cli --profile local \
        s3 rm s3://iriversland-cloud/terraform/kubernetes/garage-base.remote-terraform.tfstate \
        --exclude '*' --include '*.tfstate' --recursive
else
    docker run --rm -ti \
        --env AWS_ACCESS_KEY_ID=$TF_VAR_aws_access_key \
        --env AWS_SECRET_ACCESS_KEY=$TF_VAR_aws_secret_key \
        --env AWS_DEFAULT_REGION=$TF_VAR_aws_region \
        amazon/aws-cli \
        s3 rm s3://iriversland-cloud/terraform/kubernetes/garage-base.remote-terraform.tfstate \
        --exclude '*' --include '*.tfstate' --recursive
fi
