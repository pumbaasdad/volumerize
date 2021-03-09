#!/bin/bash

set -o errexit

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/mysql_base.sh

MYSQL_RETURN_CODE=0
MYSQL_JOB_TYPE="dump"

function databaseJob() {
  local returnCode=0;

  MYSQL_SOURCE=${VOLUMERIZE_DB_SOURCE}/volumerize-mysql

  echo "Creating ${MYSQL_SOURCE} folder if not exists"
  mkdir -p ${MYSQL_SOURCE}
  
  if [[ "$VOLUMERIZE_MYSQL_OPTIMIZE" == "true" ]]; then
    echo "Starting automatic repair and optimize for all databases..."
    mysqlcheck -h ${VOLUMERIZE_DB_HOST} -u${VOLUMERIZE_DB_USERNAME} -p${VOLUMERIZE_DB_PASSWORD} --all-databases --optimize --auto-repair --silent 2>&1
  fi

  # Based on this answer https://stackoverflow.com/a/32361604
  SIZE_BYTES=$(mysql --skip-column-names -h ${VOLUMERIZE_DB_HOST} -u ${VOLUMERIZE_DB_USERNAME} -p${VOLUMERIZE_DB_PASSWORD} ${VOLUMERIZE_DB_DATABASE} -e "SELECT ROUND(SUM(data_length * 0.8), 0) FROM information_schema.TABLES WHERE table_schema='${VOLUMERIZE_DB_DATABASE}';")
  [[ ${SIZE_BYTES} == NULL ]] && SIZE_BYTES=0

  echo "mysqldump @ ${VOLUMERIZE_DB_HOST} starts for database ${MYSQL_DATABASE} (Progress is aproximated)"
  mysqldump --single-transaction --add-drop-database --user="${VOLUMERIZE_DB_USERNAME}" --password="${VOLUMERIZE_DB_PASSWORD}" --host="${VOLUMERIZE_DB_HOST}" --databases "${VOLUMERIZE_DB_DATABASE}"  | pv --progress --size "${SIZE_BYTES:-0}" > ${MYSQL_SOURCE}/dump-${VOLUMERIZE_DB_DATABASE}.sql || returnCode=$? && true ;

  if [ "$returnCode" -gt "$MYSQL_RETURN_CODE" ]; then
    MYSQL_RETURN_CODE=$returnCode
  fi
}

databaseExecution "$@"
exit $MYSQL_RETURN_CODE
