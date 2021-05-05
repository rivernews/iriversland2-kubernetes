FROM codercom/code-server:3.9.3

# TODO: 

# TODO: require secrets injected in microservice

# install zsh & autocomplete
RUN git config --global user.name ${USER_FULL_NAME} && \
    git config --global user.email ${USER_EMAIL}

# install dev tools (doctl, terraform, kubectl)