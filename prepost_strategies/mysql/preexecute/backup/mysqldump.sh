#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

VOLUMERIZE_MYSQL_SOURCE=${VOLUMERIZE_MYSQL_SOURCE:-VOLUMERIZE_SOURCE}
export MYSQL_SOURCE=${!VOLUMERIZE_MYSQL_SOURCE}

file_env "MYSQL_PASSWORD"
check_env "Mysqldump" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_SOURCE" "MYSQL_DATABASE"

echo "Creating ${MYSQL_SOURCE}/volumerize-mysql folder if not exists"
mkdir -p ${MYSQL_SOURCE}/volumerize-mysql

echo "Starting automatic repair and optimize for all databases..."
mysqlcheck -h ${MYSQL_HOST} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} --all-databases --optimize --auto-repair --silent 2>&1

# Based on this answer https://stackoverflow.com/a/32361604
SIZE_BYTES=$(mysql --skip-column-names -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "SELECT ROUND(SUM(data_length * 0.8), 0) FROM information_schema.TABLES WHERE table_schema='${MYSQL_DATABASE}';")
[[ ${SIZE_BYTES} == NULL ]] && SIZE_BYTES=0

echo "mysqldump starts for database ${MYSQL_DATABASE} (Progress is aproximated)"
mysqldump --single-transaction --add-drop-database --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" --host="${MYSQL_HOST}" --databases "${MYSQL_DATABASE}"  | pv --progress --size "${SIZE_BYTES:-0}" > ${MYSQL_SOURCE}/volumerize-mysql/dump-${MYSQL_DATABASE}.sql
