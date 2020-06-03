# docker awscli s3
# https://docs.aws.amazon.com/cli/latest/reference/s3/index.html#use-of-exclude-and-include-filters

set -e

if [[ -z "$TF_VAR_aws_access_key" || -z "$TF_VAR_aws_secret_key" || -z "$TF_VAR_aws_region" ]]; then
    echo "One or more aws credentials are not provided, try to use local config"
    docker run --rm -ti -v ~/.aws:/root/.aws amazon/aws-cli --profile local \
        s3 rm s3://iriversland-cloud/terraform/kubernetes/ \
        --exclude '*' --include '*.tfstate' --recursive --dryrun
else
    docker run --rm -ti \
        --env AWS_ACCESS_KEY_ID=$TF_VAR_aws_access_key \
        --env AWS_SECRET_ACCESS_KEY=$TF_VAR_aws_secret_key \
        --env AWS_DEFAULT_REGION=$TF_VAR_aws_region \
        amazon/aws-cli \
        s3 rm s3://iriversland-cloud/terraform/kubernetes/ \
        --exclude '*' --include '*.tfstate' --recursive --dryrun
fi
