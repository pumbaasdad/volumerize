ARG BASE_IMAGE_TAG=latest

FROM fekide/volumerize:${BASE_IMAGE_TAG}

RUN apk add --no-cache \
    postgresql-client

COPY postexecute /postexecute
COPY preexecute /preexecute
COPY utils /opt/volumerize
