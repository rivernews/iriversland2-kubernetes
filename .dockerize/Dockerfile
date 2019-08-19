FROM hashicorp/terraform:0.12.6

# install curl
# https://stackoverflow.com/a/51209115/9814131
RUN apk --no-cache add curl bash ca-certificates sudo

# install kubectl
# https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl
RUN sudo mv ./kubectl /bin/kubectl
RUN sudo chmod +x /bin/kubectl


# RUN kubectl version --client


# ENTRYPOINT [ "/bin/kubectl" ]



# ADD https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl /usr/local/bin/kubectl

# ENV HOME=/config

# RUN set -x && \
#     apk add --no-cache curl ca-certificates bash && \
#     chmod +x /usr/local/bin/kubectl && \
#     \
#     # Create non-root user (with a randomly chosen UID/GUI).
#     adduser kubectl -Du 2342 -h /config && \
#     \
#     # Basic check it works.
#     kubectl version --client

# USER kubectl

RUN mkdir -p /terraform
ADD . /terraform
RUN sudo chmod +x /terraform

ENTRYPOINT ["/usr/local/bin/kubectl"]