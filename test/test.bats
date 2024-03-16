#!/usr/bin/env ./test/libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup_file() {
  docker version
  docker-compose version
  export COMPOSE_DIRECTORY=${BATS_TEST_DIRNAME}/compose-files
  export COMPOSE_FILE=${COMPOSE_DIRECTORY}/${TEST_IMAGE_TYPE:-default}.yml
  docker-compose --no-ansi up -d
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Wait for database initialisation
    wait_until_running mariadb 120 "MariaDB init process done. Ready for start up." "mariadbd: ready for connections."
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Wait for database initialisation
    wait_until_running mongodb 120 "MongoDB init process complete; ready for start up." "Waiting for connections"
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    # Wait for database initialisation
    wait_until_running postgres 120 "PostgreSQL init process complete; ready for start up." "database system is ready to accept connections"
  fi
}

setup() {
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Initialize database with simple testing values
    mysql_initialize_db
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Initialize database with simple testing values
    mongo_initialize_db
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    # Initialize database with simple testing values
    postgres_initialize_db
  else
    docker-compose exec -T volumerize bash -c 'echo test | cat > /source/test.txt'
  fi
}


@test "version" {

  run docker-compose exec -T volumerize duplicity -V
  assert_success

}

@test "manual backup" {

  run docker-compose exec -T volumerize backup
  assert_success

  run echo $(docker-compose exec -T volumerize bash -c "ls --color=never /backup | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

}

@test "jobber" {

  run docker-compose exec -T volumerize jobber test VolumerizeBackupJob
  assert_success

  run echo $(docker-compose exec -T volumerize bash -c "ls --color=never /backup | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

}

@test "keep n backups" {
  for i in {1..5}
  do
    if [ $TEST_IMAGE_TYPE == default ]; then
      run docker-compose exec -T volumerize bash -c "echo test${i} | cat >> /source/test.txt"
      assert_success
    fi
    run docker-compose exec -T -e REMOVE_ALL_BUT_N_FULL=3 volumerize backupFull
    assert_success
    assert_output
    sleep 1
  done

  run echo $(docker-compose exec -T volumerize bash -c "ls --color=never /backup | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '9'

}

@test "restore" {

  run docker-compose exec -T volumerize backup
  assert_success
  assert_output

  # Corrupt data to simulate necessity of restore
  if [ $TEST_IMAGE_TYPE == default ]; then
    run docker-compose exec -T volumerize bash -c 'echo wrong | cat > /source/test.txt'
    assert_success
  elif [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_drop_table
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_drop_collection
    assert_success
    run mongo_get_values
    refute_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_drop_table
    assert_success
  fi

  run docker-compose exec -T volumerize restore
  assert_success

  # Validate that backup was restored
  if [ $TEST_IMAGE_TYPE == default ]; then
    run docker-compose exec -T volumerize cat /source/test.txt 
    assert_success
    assert_output --partial test
  elif [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_check_values
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_get_values
    assert_success
    assert_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_check_values
    assert_success
  fi

}

@test "container_version" {
  run docker run $TEST_IMAGE /bin/sh -c 'cat /.expected_os_release /.expected_python_version /.expected_poetry_version | diff /.container_version -'
  assert_success
}

teardown() {
  docker-compose --ansi never exec -T volumerize bash -c 'rm -rf /volumerize-cache/* /backup/* /source/*'
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Drop Table
    mysql_drop_table
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Drop collection contents
    mongo_drop_collection
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    # Drop Table
    postgres_drop_table
  fi
  docker-compose --ansi never logs
}

teardown_file() {
  docker-compose --ansi never down -v
}

function wait_until_running() {
  local service=$1
  local timeout=$2
  local first_line=$3
  local last_line=$4

  local wait_time=0

  until docker-compose --no-ansi logs $service | grep "${first_line}" || [ $wait_time -ge $timeout ];
  do
    echo "waiting for ${service} to be up and running"
    wait_time=$(( $wait_time + 1 ))
    sleep 1
  done
  echo "initialization done, waiting for ${service} to start"
  # Wait unitl service can handle connections
  until docker-compose --no-ansi logs --tail 5 $service | grep "${last_line}" || [ $wait_time -ge $timeout ];
  do
    echo "waiting for ${service} to be up and running"
    wait_time=$(( $wait_time + 1 ))
    sleep 1
  done
  if [ $wait_time -ge $timeout ]; then
    echo "${service} took too long to initialize"
    return 1
  fi
}

mysql_table_name=test
mysql_column_name=test
mysql_value=test
mysql_user=root
mysql_pwd=1234

mysql_default_command="docker-compose exec -T mariadb mariadb -u ${mysql_user} --password=${mysql_pwd} somedatabase -e "

function mysql_initialize_db() {
  eval ${mysql_default_command} "\"create table ${mysql_table_name}(${mysql_column_name} varchar(100))\""
  eval ${mysql_default_command} "\"insert into ${mysql_table_name} (${mysql_column_name}) values ('${mysql_value}')\""
}


function mysql_drop_table() {
  eval ${mysql_default_command} "\"drop table ${mysql_table_name}\""
}

function mysql_get_values() {
  eval ${mysql_default_command} "\"select * from ${mysql_table_name}\""
}

function mysql_check_values() {
  local actual=$( mysql_get_values | tr -d '\r' )
  local expected=$( echo ${mysql_value} )
  echo "-- Actual --"
  echo "$actual"
  echo "-- Expected --"
  echo "$expected"
  if [ ${actual} != ${expected} ]; then
    echo "-- Difference --"
    diff <(echo "$actual") <(echo "$expected")
    echo "-- Hexdump --"
    echo "- Actual -"
    hexdump <(echo "$actual")
    echo "- Expected -"
    hexdump <(echo "$expected")
    return 1;
  fi
}

mongo_user=root
mongo_pwd=1234

mongo_default_command="docker-compose exec -T mongodb mongo --quiet -u ${mongo_user} -p ${mongo_pwd} "

function mongo_initialize_db() {
  eval ${mongo_default_command} "\"/scripts/init.js\""
}


function mongo_drop_collection() {
  eval ${mongo_default_command} "\"/scripts/drop.js\""
}

function mongo_get_values() {
  eval ${mongo_default_command} "\"/scripts/find.js\""
}

postgres_table_name=test
postgres_column_name=test
postgres_database=postgres
postgres_value=test
postgres_user=postgres
postgres_pwd=1234

postgres_default_command="docker-compose exec -T -e PGPASSWORD=${postgres_pwd} postgres psql -qtA --username=${postgres_user} ${postgres_database} -c "

function postgres_initialize_db() {
  eval ${postgres_default_command} "\"create table ${postgres_table_name}(${postgres_column_name} varchar(100))\""
  eval ${postgres_default_command} "\"insert into ${postgres_table_name} (${postgres_column_name}) values ('${postgres_value}')\""
}


function postgres_drop_table() {
  eval ${postgres_default_command} "\"drop table ${postgres_table_name}\""
}

function postgres_get_values() {
  eval ${postgres_default_command} "\"select * from ${postgres_table_name}\""
}

function postgres_check_values() {
  local actual=$( postgres_get_values | tr -d '\r' )
  local expected=$( echo "${postgres_value}" )
  echo "-- Actual --"
  echo "$actual"
  echo "-- Expected --"
  echo "$expected"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "-- Difference --"
    diff <(echo "$actual") <(echo "$expected")
    echo "-- Hexdump --"
    echo "- Actual -"
    hexdump <(echo "$actual")
    echo "- Expected -"
    hexdump <(echo "$expected")
    return 1;
  fi
}
