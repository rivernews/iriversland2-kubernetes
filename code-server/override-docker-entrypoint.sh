#!/bin/sh

# see official image entrypoint:
# https://github.com/cdr/code-server/blob/main/ci/release-image/Dockerfile

/usr/bin/entrypoint.sh --bind-addr 0.0.0.0:${CODE_SERVER_PORT:-8080} ${CODE_SERVER_VOLUME_MOUNT:-/home/coder}
