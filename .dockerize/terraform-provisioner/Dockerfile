FROM hashicorp/terraform:0.12.18



# install curl
# https://stackoverflow.com/a/51209115/9814131
# new curl release issue: https://stackoverflow.com/a/57982728/9814131
RUN apk --upgrade --no-cache add curl && apk --no-cache add bash ca-certificates sudo

# install kubectl
# https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl
RUN sudo mv ./kubectl /bin/kubectl
RUN sudo chmod +x /bin/kubectl

# load terraform script code base into image
RUN mkdir -p /terraform
ADD . /terraform
RUN sudo chmod +x /terraform

ENTRYPOINT ["/usr/local/bin/kubectl"]