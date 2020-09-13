#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/mysql_base.sh

MYSQL_RETURN_CODE=0
MYSQL_JOB_TYPE="restore"

function databaseJob() {
  local returnCode=0;

  MYSQL_SOURCE=${VOLUMERIZE_DB_SOURCE}/volumerize-mysql

  echo "mysql import of ${VOLUMERIZE_DB_HOST} starts"
  pv ${MYSQL_SOURCE}/dump-${MYSQL_DATABASE}.sql | mysql -h ${VOLUMERIZE_DB_HOST} -u ${VOLUMERIZE_DB_USERNAME} -p${VOLUMERIZE_DB_PASSWORD} ${VOLUMERIZE_DB_DATABASE} || returnCode=$? && true ;
  echo "Import done"
  if [ "$returnCode" -gt "$MYSQL_RETURN_CODE" ]; then
    MYSQL_RETURN_CODE=$returnCode
  fi
}

if [ "${DUPLICITY_RETURN_CODE:-0}" == 0 ]; then
  databaseExecution "$@"
  exit $MYSQL_RETURN_CODE
fi
