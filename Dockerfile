FROM rclone/rclone:1.62.2 as rclone
FROM docker:23.0.4 as docker

FROM alpine:3.17.3
LABEL maintainer="Pumbaa's Dad <32616257+pumbaasdad@users.noreply.github.com>"

ARG JOBBER_VERSION=1.4.4

ENV POETRY_NO_INTERACTION=1 \
  POETRY_VIRTUALENVS_CREATE=false

RUN apk upgrade --update && \
    apk add \
      bash \
      tzdata \
      tini \
      su-exec \
      gzip \
      gettext \
      tar \
      wget \
      curl \
      gmp-dev \
      tzdata \
      openssh \
      openssl \
      ca-certificates \
      python3-dev \
      gcc \
      glib \
      gnupg \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-cryptography \
      libffi-dev \
      librsync \
      librsync-dev \
      libcurl \
      py3-pip && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir wheel setuptools-scm && \
    pip3 install --no-cache-dir \
      pyrax && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize /var/jobber/0 && \
    # Install Jobber
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Install poetry
    curl -sSL https://install.python-poetry.org | python3 - && \
    # Cleanup
    apk del \
      curl \
      wget \
      linux-headers \
      musl-dev && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

COPY poetry.lock pyproject.toml /

RUN /root/.local/bin/poetry install --no-ansi && \
    apk del \
      alpine-sdk \
      gcc \
      librsync-dev \
      python3-dev

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
