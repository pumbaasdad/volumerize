#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/postgres_base.sh

POSTGRESDUMP_RETURN_CODE=0
POSTGRES_JOB_TYPE="dump"

function databaseJob() {
  local returnCode=0;

  POSTGRES_SOURCE=${VOLUMERIZE_DB_SOURCE}/volumerize-postgres
  echo "Creating $MONGO_SOURCE folder if not exists"
  mkdir -p $POSTGRES_SOURCE
  rm -rf $POSTGRES_SOURCE/*
  export PGPASSWORD="${VOLUMERIZE_DB_PASSWORD}"

  echo "postgresdump of ${VOLUMERIZE_DB_HOST}/${VOLUMERIZE_DB_DATABASE} starts"
  pg_dump --host ${VOLUMERIZE_DB_HOST} --port ${VOLUMERIZE_DB_PORT} --username ${VOLUMERIZE_DB_USERNAME} --format directory --file ${POSTGRES_SOURCE} ${VOLUMERIZE_DB_DATABASE} || returnCode=$? && true ;

  if [ "$returnCode" -gt "$POSTGRESDUMP_RETURN_CODE" ]; then
    POSTGRESDUMP_RETURN_CODE=$returnCode
  fi
}

databaseExecution "$@"
exit $POSTGRESDUMP_RETURN_CODE
