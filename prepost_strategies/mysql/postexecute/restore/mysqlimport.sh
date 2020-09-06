#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

VOLUMERIZE_MYSQL_SOURCE=${VOLUMERIZE_MYSQL_SOURCE:-VOLUMERIZE_SOURCE}
export MYSQL_SOURCE=${!VOLUMERIZE_MYSQL_SOURCE}

file_env "MYSQL_PASSWORD"
check_env "mysqlimport" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST" "MYSQL_DATABASE"

echo "mysql import starts"
pv ${MYSQL_SOURCE}/volumerize-mysql/dump-${MYSQL_DATABASE}.sql | mysql -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} $MYSQL_DATABASE
echo "Import done"
