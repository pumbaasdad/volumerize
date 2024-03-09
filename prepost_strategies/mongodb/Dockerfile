ARG BASE_IMAGE=

FROM ${BASE_IMAGE}

RUN apk add --no-cache \
    mongodb-tools

COPY postexecute /postexecute
COPY preexecute /preexecute
COPY utils /opt/volumerize
