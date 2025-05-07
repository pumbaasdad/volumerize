FROM rclone/rclone:1.69.2 AS rclone
FROM docker:28.1.1 AS docker

FROM alpine:3.21.3 AS alpine

FROM python:3.13.2 AS python
RUN python -V > .python_version

FROM ghcr.io/pumbaasdad/poetry:2025-03-30 AS poetry
RUN poetry -V > .poetry_version

FROM ghcr.io/pumbaasdad/poetry:2025-03-30

LABEL maintainer="Pumbaa's Dad <32616257+pumbaasdad@users.noreply.github.com>"

ARG JOBBER_VERSION=1.4.4

COPY --from=alpine /etc/os-release /.expected_os_release
COPY --from=python /.python_version /.expected_python_version
COPY --from=poetry /.poetry_version /.expected_poetry_version

RUN apk upgrade --update && \
    apk add \
      bash \
      tini \
      su-exec \
      gzip \
      gettext \
      tar \
      wget \
      curl \
      openssh \
      openssl \
      gcc \
      glib \
      gnupg \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      libffi-dev \
      librsync \
      librsync-dev \
      libcurl && \
    CFLAGS=-Wno-int-conversion pip3 install --no-cache-dir pyrax && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize /var/jobber/0 && \
    # Install Jobber
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Cleanup
    apk del \
      curl \
      wget && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

COPY poetry.lock pyproject.toml /

RUN poetry install --no-ansi && \
    apk del \
      alpine-sdk \
      gcc \
      librsync-dev \
      linux-headers \
      musl-dev

COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=docker /usr/local/bin/ /usr/local/bin/

ENV VOLUMERIZE_HOME=/etc/volumerize \
    VOLUMERIZE_CACHE=/volumerize-cache \
    VOLUMERIZE_SCRIPT_DIR=/opt/volumerize \
    PATH=$PATH:/etc/volumerize \
    GOOGLE_DRIVE_SETTINGS=/credentials/cred.file \
    GOOGLE_DRIVE_CREDENTIAL_FILE=/credentials/googledrive.cred \
    GPG_TTY=/dev/console

USER root
WORKDIR /etc/volumerize
VOLUME ["/volumerize-cache"]
COPY imagescripts/ /opt/volumerize/
COPY scripts/ /etc/volumerize/
COPY postexecute/ /postexecute
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
