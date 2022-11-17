# base image
FROM ubuntu:20.04
# FROM ubuntu:focal

#input GitHub runner version argument
ARG RUNNER_VERSION=2.299.1

ARG IMAGE_VERSION

# Metadata as defined at http://label-schema.org
ARG BUILD_DATE

ENV DEBIAN_FRONTEND=noninteractive

LABEL Author="Colby Williams"
LABEL Email="colbyw@microsoft.com"
LABEL GitHub="https://github.com/colbylwilliams"
LABEL BaseImage="ubuntu:20.04"
LABEL RunnerVersion=${RUNNER_VERSION}

LABEL maintainer="Microsoft" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.url="https://github.com/colbylwilliams/aca-runner" \
    org.opencontainers.image.source="https://github.com/colbylwilliams/aca-runner" \
    org.opencontainers.image.version=$IMAGE_VERSION \
    org.opencontainers.image.vendor="Microsoft" \
    org.opencontainers.image.title="ACA GitHub self-hosted runner" \
    org.opencontainers.image.description="The ACA GitHub self-hosted runner is used to build images using packer." \
    org.opencontainers.image.documentation="https://github.com/colbylwilliams/aca-runner/tree/main/runner" \
    org.opencontainers.image.licenses="MIT" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Microsoft" \
    org.label-schema.name="ACA GitHub self-hosted runner" \
    org.label-schema.version=$IMAGE_VERSION \
    org.label-schema.license="MIT" \
    org.label-schema.description="The ACA GitHub self-hosted runner is used to build images using packer." \
    org.label-schema.url="https://github.com/colbylwilliams/aca-runner" \
    org.label-schema.usage="https://github.com/colbylwilliams/aca-runner/tree/main/runner" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-url="https://github.com/colbylwilliams/aca-runner.git" \
    org.label-schema.docker.cmd="docker run acarunners.azurecr.io/acarunner:$IMAGE_VERSION"
# org.label-schema.docker.cmd="docker run ghcr.io/colbylwilliams/aca-runner/acarunner:$IMAGE_VERSION"

# update the base packages + add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m docker

# install the packages and dependencies along with jq so we can parse JSON (add additional packages as necessary)
RUN apt-get install -y --no-install-recommends \
    curl nodejs wget unzip vim git azure-cli jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# add over the start.sh script
ADD scripts/start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]