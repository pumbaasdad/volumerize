#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/mongo_base.sh

MONGODUMP_RETURN_CODE=0
MONGO_JOB_TYPE="restore"

function databaseJob() {
  local returnCode=0;

  MONGO_SOURCE=${VOLUMERIZE_DB_SOURCE}/volumerize-mongo

  echo "mongorestore of ${VOLUMERIZE_DB_HOST} starts"
  mongorestore --host ${VOLUMERIZE_DB_HOST} --port ${VOLUMERIZE_DB_PORT} --username ${VOLUMERIZE_DB_USERNAME} --password "${VOLUMERIZE_DB_PASSWORD}" ${MONGO_SOURCE} || returnCode=$? && true ;

  if [ "$returnCode" -gt "$MONGODUMP_RETURN_CODE" ]; then
    MONGODUMP_RETURN_CODE=$returnCode
  fi
}

if [ "${DUPLICITY_RETURN_CODE}" == 0 ]; then
  databaseExecution "$@"
  exit $MONGODUMP_RETURN_CODE
fi
