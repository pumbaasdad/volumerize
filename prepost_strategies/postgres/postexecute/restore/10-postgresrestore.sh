#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/postgres_base.sh

POSTGRESDUMP_RETURN_CODE=0
POSTGRES_JOB_TYPE="restore"

function databaseJob() {
  local returnCode=0;

  POSTGRES_SOURCE=${VOLUMERIZE_DB_SOURCE}/volumerize-postgres
  export PGPASSWORD="${VOLUMERIZE_DB_PASSWORD}"

  echo "postgresrestore of ${VOLUMERIZE_DB_HOST}/${VOLUMERIZE_DB_DATABASE} starts"
  pg_restore --host ${VOLUMERIZE_DB_HOST} --port ${VOLUMERIZE_DB_PORT} --username ${VOLUMERIZE_DB_USERNAME} -d ${VOLUMERIZE_DB_DATABASE} ${POSTGRES_SOURCE} || returnCode=$? && true ;

  if [ "$returnCode" -gt "$POSTGRESDUMP_RETURN_CODE" ]; then
    POSTGRESDUMP_RETURN_CODE=$returnCode
  fi
}

if [ "${DUPLICITY_RETURN_CODE}" == 0 ]; then
  databaseExecution "$@"
  exit $POSTGRESDUMP_RETURN_CODE
fi
