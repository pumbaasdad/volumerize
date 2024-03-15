FROM alpine:3.19
FROM python:3.12.2-alpine3.19

RUN apk upgrade --update && \
    apk add \
      coreutils

COPY entrypoint.py /entrypoint.py
ENTRYPOINT ["/entrypoint.py"]