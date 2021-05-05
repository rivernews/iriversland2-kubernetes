FROM codercom/code-server:3.9.3

# TODO: run docker in pod / or build on circleCI|GithubAction

# TODO: require secrets injected in microservice
ENV USER_FULL_NAME=
ENV USER_EMAIL=

ENV TERRAFORM_VERSION=0.12.18
ENV DOCTL_VERSION=1.36.0

# setup git
# RUN git config --global user.name ${USER_FULL_NAME} && \
    # git config --global user.email ${USER_EMAIL}

# install zsh & autocomplete
RUN echo -e "INFO: Installing Oh my Zsh framework..." && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh syntax-highlighting - let shell commands keywords be recognized and displayed in green, etc
# https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh autosuggestions (grayed-out words hinting you)
# https://github.com/zsh-users/zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# TODO: add zsh plugin

# TODO: set vscode default shell to zsh

# install dev tools (doctl, terraform, kubectl)
RUN sudo apt-get update -y && sudo apt-get install unzip

RUN cd /tmp && curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl && \
    sudo mv ./kubectl /bin/kubectl && \
    sudo chmod +x /bin/kubectl

RUN cd /tmp && curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    sudo unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin

RUN cd /tmp && curl -OL https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz && \
    sudo tar xf doctl-${DOCTL_VERSION}-linux-amd64.tar.gz --directory /usr/bin

RUN rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/*