#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

VOLUMERIZE_MONGO_SOURCE=${VOLUMERIZE_MONGO_SOURCE:-VOLUMERIZE_SOURCE}
export MONGO_SOURCE=${!VOLUMERIZE_MONGO_SOURCE}

file_env "MONGO_PASSWORD"
check_env "mongodump" "MONGO_USERNAME" "MONGO_PASSWORD" "MONGO_HOST" "MONGO_PORT" "MONGO_SOURCE"

MONGO_SOURCE=${MONGO_SOURCE}/volumerize-mongo

echo "Creating $MONGO_SOURCE folder if not exists"
mkdir -p $MONGO_SOURCE

echo "mongodump starts"
mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} --username ${MONGO_USERNAME} --password "${MONGO_PASSWORD}" --out ${MONGO_SOURCE}