ARG BASE_IMAGE_TAG=latest

FROM fekide/volumerize:${BASE_IMAGE_TAG}

RUN apk add --no-cache \
    mysql-client pv

COPY postexecute /postexecute
COPY preexecute /preexecute
COPY scripts /etc/volumerize
