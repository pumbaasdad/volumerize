source /preexecute/utils/check-env.sh

check_env "Mysqldump" "MYSQL_PASSWORD" "MYSQL_USERNAME" "MYSQL_HOST"

echo "Creating $VOLUMERIZE_SOURCE folder if not exists"
mkdir -p $VOLUMERIZE_SOURCE/volumerize-mysql/

#echo "Starting automatic repair and optimize for all databases..."
#mysqlcheck -h ${MYSQL_HOST} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} --all-databases --optimize --auto-repair --silent 2>&1

for MYSQL_DATABASE in `mysql -h ${MYSQL_HOST} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -Bse 'show databases'`; do

  # Based on this answer https://stackoverflow.com/a/32361604
  #SIZE_BYTES=$(mysql --skip-column-names -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "SELECT ROUND(SUM(data_length * 0.8), 0) FROM information_schema.TABLES WHERE table_schema='${MYSQL_DATABASE}';")

  echo "mysqldump starts " ${MYSQL_DATABASE}
  mysqldump --databases "${MYSQL_DATABASE}" --single-transaction --add-drop-database --user="${MYSQL_USERNAME}" --password="${MYSQL_PASSWORD}" --host="${MYSQL_HOST}" > ${VOLUMERIZE_SOURCE}/volumerize-mysql/dump-${MYSQL_DATABASE}.sql
  
done
