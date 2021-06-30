FROM codercom/code-server:3.10.2

ENV DOCTL_VERSION=1.36.0

# install dev tools (doctl, terraform, kubectl, pyenv)
RUN sudo apt-get update -y && \
    sudo apt-get install -y unzip docker.io zsh && \
    docker --version && \
    # for pyenv
    # https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    sudo apt-get install make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

RUN cd /tmp && curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl && \
    sudo mv ./kubectl /bin/kubectl && \
    sudo chmod +x /bin/kubectl

RUN curl https://pyenv.run | bash

# Terraform Swithcer
# https://github.com/warrensbox/terraform-switcher
#
# List all versions
# tfswitch -l
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | sudo sh

RUN cd /tmp && curl -OL https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz && \
    sudo tar xf doctl-${DOCTL_VERSION}-linux-amd64.tar.gz --directory /usr/bin

# `rclone config`
# select #15 Google drive
# check out client id & secret (both is required!) at
# https://console.cloud.google.com/apis/credentials?project=appl-tracky&folder=&organizationId=
RUN cd /tmp && curl https://rclone.org/install.sh | sudo bash

RUN sudo rm -rf /tmp/* && \
    sudo rm -rf /var/cache/apk/* && \
    sudo rm -rf /var/tmp/*

COPY override-docker-entrypoint.sh /tmp/
RUN sudo /bin/chmod -R 777 /tmp/override-docker-entrypoint.sh
ENTRYPOINT [ "/tmp/override-docker-entrypoint.sh" ]
