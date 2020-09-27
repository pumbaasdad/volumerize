#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/mongo_base.sh

MONGODUMP_RETURN_CODE=0
MONGO_JOB_TYPE="dump"

function databaseJob() {
  local returnCode=0;

  MONGO_SOURCE=${VOLUMERIZE_DB_SOURCE}/volumerize-mongo
  echo "Creating $MONGO_SOURCE folder if not exists"
  mkdir -p $MONGO_SOURCE

  echo "mongodump of ${VOLUMERIZE_DB_HOST} starts"
  mongodump --host ${VOLUMERIZE_DB_HOST} --port ${VOLUMERIZE_DB_PORT} --username ${VOLUMERIZE_DB_USERNAME} --password "${VOLUMERIZE_DB_PASSWORD}" --out ${MONGO_SOURCE} || returnCode=$? && true ;

  if [ "$returnCode" -gt "$MONGODUMP_RETURN_CODE" ]; then
    MONGODUMP_RETURN_CODE=$returnCode
  fi
}

databaseExecution "$@"
exit $MONGODUMP_RETURN_CODE
