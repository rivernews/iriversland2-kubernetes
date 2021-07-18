#!/bin/sh

# installation
if [ ! -e "$HOME/.zshrc" ]; then
    # install zsh & autocomplete
    echo -e "INFO: Installing Oh my Zsh framework..." && \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # zsh syntax-highlighting - let shell commands keywords be recognized and displayed in green, etc
    # https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # zsh autosuggestions (grayed-out words hinting you)
    # https://github.com/zsh-users/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# TODO: add zsh plugin - so that autocomplete and highlight can be used, like below
# plugins=(
#     git
#     zsh-syntax-highlighting
#     zsh-autosuggestions
#   vscode
# )

# TODO: install settings-sync extension and download settings

# setup git
USER_EMAIL=${ADMINS#*,}
USER_FULL_NAME=${ADMINS%,"${USER_EMAIL}"}
git config --global user.email ${USER_EMAIL}
git config --global user.name ${USER_FULL_NAME}

# TODO: setup rclone

# clone frequently used repos
if [ -d "$HOME/Documents/repos" ]; then
    echo "Already set up repo directory, skipping..."
else
    echo "Setup repo directory..."
    mkdir -p ~/Documents/repos
    cd ~/Documents/repos
    git clone https://github.com/rivernews/iriversland2-kubernetes.git && \
    git clone https://github.com/rivernews/secret-management.git && \
    git clone https://github.com/rivernews/macos-reinstall.git

    # TODO: set up secret-management repo
    # rclone sync gd:/Personal/macOS/repo-backups/secret-management/secrets ~/Documents/repos/secret-management/secrets
    # rclone copy gd:/Personal/macOS/repo-backups/secret-management/local.backend.credentials.tfvars ~/Documents/repos/secret-management
    # terraform init -backend-config=local.backend.credentials.tfvars
fi

# see official image entrypoint:
# https://github.com/cdr/code-server/blob/main/ci/release-image/Dockerfile

/usr/bin/entrypoint.sh --bind-addr 0.0.0.0:${CODE_SERVER_PORT:-8080} --user-data-dir ${CODE_SERVER_VOLUME_MOUNT:-/home/coder} $HOME
