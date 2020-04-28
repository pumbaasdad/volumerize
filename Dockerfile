FROM alpine:3.11.5
LABEL maintainer="Felix Haase <felix.haase@feki.de>"

ARG JOBBER_VERSION=1.4.1
ARG DOCKER_VERSION=1.12.2
ARG DUPLICITY_VERSION=0.8.12
ARG DUPLICITY_SERIES=0.8
ARG DUPLICITY_STABILITY=1612
ARG MEGATOOLS_VERSION=1.10.3

RUN apk upgrade --update && \
    apk add \
      bash \
      tzdata \
      vim \
      tini \
      su-exec \
      gzip \
      tar \
      wget \
      curl \
      build-base \
      glib-dev \
      gmp-dev \
      asciidoc \
      curl-dev \
      tzdata \
      openssh \
      libressl-dev \
      libressl \
      duply \
      ca-certificates \
      python-dev \
      libffi-dev \
      librsync-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-cryptography \
      librsync \
      librsync-dev \
      # python2-dev \
      mysql-client \
      pv \
      nano \
      py-pip && \
    pip install --upgrade pip && \
    pip install --no-cache-dir \
      fasteners \
      PyDrive \
      chardet \
      azure-storage \
      boto \
      lockfile \
      paramiko \
      pexpect \
      pycryptopp \
      python-keystoneclient \
      python-swiftclient \
      requests==2.23.0 \
      requests_oauthlib \
      urllib3 \
      b2 \
      dropbox==6.9.0 \
      duplicity==${DUPLICITY_VERSION}.${DUPLICITY_STABILITY} && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize && \
    # Setup users
    export CONTAINER_UID=1000 && \
    export CONTAINER_GID=1000 && \
    export CONTAINER_USER=jobber_client && \
    export CONTAINER_GROUP=jobber_client && \
    # Install tools
    apk add \
      go \
      git \
      curl \
      wget \
      make && \
    # Install Jobber
    addgroup -g $CONTAINER_GID jobber_client && \
    adduser -u $CONTAINER_UID -G jobber_client -s /bin/bash -S jobber_client && \
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Install Docker CLI
    curl -fSL "https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz && \
    export DOCKER_SHA=43b2479764ecb367ed169076a33e83f99a14dc85 && \
    echo 'Calculated checksum: '$(sha1sum /tmp/docker.tgz) && \
    echo "$DOCKER_SHA  /tmp/docker.tgz" | sha1sum -c - && \
    tar -xzvf /tmp/docker.tgz -C /tmp && \
    cp /tmp/docker/docker /usr/local/bin/ && \
    # Install MEGAtools
    curl -fSL "https://megatools.megous.com/builds/megatools-${MEGATOOLS_VERSION}.tar.gz" -o /tmp/megatools.tgz && \
    tar -xzvf /tmp/megatools.tgz -C /tmp && \
    cd /tmp/megatools-${MEGATOOLS_VERSION} && \
    ./configure && \
    make && \
    make install && \
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python-dev \
      libffi-dev \
      libressl-dev \
      libressl \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      librsync-dev \
      make && \
    apk add \
        openssl && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

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
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
