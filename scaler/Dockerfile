FROM python:3.10

ARG IMAGE_VERSION

# Metadata as defined at http://label-schema.org
ARG BUILD_DATE

LABEL Author="Colby Williams"
LABEL Email="colbyw@microsoft.com"
LABEL GitHub="https://github.com/colbylwilliams"
LABEL BaseImage="python:3.10"

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
    org.label-schema.docker.cmd="docker run acarunners.azurecr.io/acascaler:$IMAGE_VERSION"
# org.label-schema.docker.cmd="docker run ghcr.io/colbylwilliams/aca-runner/acascaler:$IMAGE_VERSION"

WORKDIR /app

COPY __init__.py /app/__init__.py
COPY webhooks.py /app/webhooks.py
COPY requirements.txt /app/requirements.txt

RUN pip3 install -r requirements.txt

# EXPOSE 5000
EXPOSE 80
EXPOSE 443

CMD ["python", "webhooks.py"]