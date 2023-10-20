ARG VARIANT="jammy"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y xdg-utils postgresql-client jq \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* 
