FROM rclone/rclone:1.61.1 as rclone
FROM docker:23.0.1 as docker

FROM alpine:3.17.1
LABEL maintainer="Felix Haase <felix.haase@feki.de>"

ARG JOBBER_VERSION=1.4.4
ARG DUPLICITY_VERSION=1.2.2

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
      azure-core \
      azure-storage-blob \
      boto \
      boto3 \
      b2sdk \
      boxsdk[jwt] \
      dropbox \
      fasteners \
      gdata-python3 \
      google-api-python-client>=2.2.0 \
      google-auth-oauthlib \
      jottalib \
      mediafire \
      megatools \
      paramiko \
      pexpect \
      psutil \
      PyDrive \
      PyDrive2 \
      pyrax \
      python-swiftclient \
      python-keystoneclient \
      requests \
      requests-oauthlib \
      pycrypto \
      urllib3 \
      apprise \
      duplicity==${DUPLICITY_VERSION} && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize /var/jobber/0 && \
    # Install Jobber
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Cleanup
    apk del \
      curl \
      wget \
      python3-dev \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      librsync-dev && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

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
