ARG BASE_IMAGE_TAG=latest

FROM fekide/volumerize:${BASE_IMAGE_TAG}

RUN apk add --no-cache \
    mongodb-tools

COPY postexecute /postexecute
COPY preexecute /preexecute
