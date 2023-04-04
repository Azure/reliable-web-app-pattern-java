ARG VARIANT=jammy
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y xdg-utils pv \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://aka.ms/install-azd.sh | bash
