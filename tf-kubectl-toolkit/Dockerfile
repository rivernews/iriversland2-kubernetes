# Dockerfile referred to 
# https://github.com/broadinstitute/docker-terraform
FROM alpine:3.10

ENV TERRAFORM_VERSION=0.12.18

# install curl
# https://stackoverflow.com/a/51209115/9814131
# new curl release issue: https://stackoverflow.com/a/57982728/9814131
# RUN apk --upgrade --no-cache add curl && apk --no-cache add bash ca-certificates sudo
RUN apk update && \
    apk add curl jq python bash ca-certificates sudo git openssl unzip wget && \
    cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
    # install kubectl
    # https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl && \
    sudo mv ./kubectl /bin/kubectl && \
    sudo chmod +x /bin/kubectl && \
    # clean up
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/*

# load terraform script code base into image
RUN mkdir -p /terraform
ADD terraform /terraform

ENTRYPOINT []

CMD ["bash"]

# you can run this container as a terraform-kubectl toolkit
# like below:
#
# cd to terraform files directory
# docker run --rm -v $(pwd):$(pwd) -w $(pwd) \
# --env TF_VAR_aws_access_key=${TF_VAR_aws_access_key} \
# --env TF_VAR_aws_secret_key=${TF_VAR_aws_secret_key} \
# --env TF_VAR_aws_region=${TF_VAR_aws_region} \
# --env TF_BACKEND_region=${TF_BACKEND_region} \
# --env SHORT_TRAVIS_COMMIT=${SHORT_TRAVIS_COMMIT} \
# shaungc/terraform-kubectl-image bash -c '\
#     echo "" \
#     && echo "" \
#     && echo "Inside terraform temp container" \
#     && env \
#     && /bin/terraform init \
#         -backend-config="access_key=${TF_VAR_aws_access_key}" \
#         -backend-config="secret_key=${TF_VAR_aws_secret_key}" \
#         -backend-config="region=${TF_BACKEND_region}" \
#     && /bin/terraform validate \
#     && /bin/terraform plan -var="app_container_image_tag=${SHORT_TRAVIS_COMMIT}" \
#     && /bin/terraform apply -auto-approve -var="app_container_image_tag=${SHORT_TRAVIS_COMMIT}" \
# '
