ARG BASE_IMAGE=

FROM ${BASE_IMAGE}

RUN apk add --no-cache \
    mysql-client pv

COPY postexecute /postexecute
COPY preexecute /preexecute
COPY utils /opt/volumerize
