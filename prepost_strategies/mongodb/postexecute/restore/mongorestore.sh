#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

VOLUMERIZE_MONGO_SOURCE=${VOLUMERIZE_MONGO_SOURCE:-VOLUMERIZE_SOURCE}
export MONGO_SOURCE=${!VOLUMERIZE_MONGO_SOURCE}

file_env "MONGO_PASSWORD"
check_env "mongorestore" "MONGO_USERNAME" "MONGO_PASSWORD" "MONGO_HOST" "MONGO_PORT" "MONGO_SOURCE"

MONGO_SOURCE=${MONGO_SOURCE}/volumerize-mongo

echo "mongorestore starts"
mongorestore --host ${MONGO_HOST} --port ${MONGO_PORT} --username ${MONGO_USERNAME} --password "${MONGO_PASSWORD}" ${MONGO_SOURCE}
echo "Import done"