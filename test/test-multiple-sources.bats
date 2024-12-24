#!/usr/bin/env ./test/libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup_file() {
  docker version
  docker compose version
  export COMPOSE_DIRECTORY=${BATS_TEST_DIRNAME}/compose-files
  export COMPOSE_FILE=${COMPOSE_DIRECTORY}/multiple-${TEST_IMAGE_TYPE:-default}.yml
  docker compose --no-ansi up -d
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Wait for database initialisation
    wait_until_running mariadb1 120 "MariaDB init process done. Ready for start up." "mariadbd: ready for connections."
    wait_until_running mariadb2 120 "MariaDB init process done. Ready for start up." "mariadbd: ready for connections."
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Wait for database initialisation
    wait_until_running mongodb1 120 "MongoDB init process complete; ready for start up." "Waiting for connections"
    wait_until_running mongodb2 120 "MongoDB init process complete; ready for start up." "Waiting for connections"
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    # Wait for database initialisation
    wait_until_running postgres1 120 "PostgreSQL init process complete; ready for start up." "database system is ready to accept connections"
    wait_until_running postgres2 120 "PostgreSQL init process complete; ready for start up." "database system is ready to accept connections"
  fi
}

setup() {
  docker compose exec -T volumerize bash -c 'echo test | cat > /source/1/test.txt'
  docker compose exec -T volumerize bash -c 'echo test | cat > /source/2/test.txt'
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Initialize database with simple testing values
    mysql_initialize_db mariadb1
    mysql_initialize_db mariadb2
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Initialize database with simple testing values
    mongo_initialize_db mongodb1
    mongo_initialize_db mongodb2
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    # Initialize database with simple testing values
    postgres_initialize_db postgres1
    postgres_initialize_db postgres2
  fi
}

@test "version" {

  run docker compose exec -T volumerize duplicity -V
  assert_success

}

@test "backup all" {

  run docker compose exec -T volumerize backup
  assert_success

  run echo $(docker compose exec -T volumerize bash -c "ls --color=never /backup/1 | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

  run echo $(docker compose exec -T volumerize bash -c "ls --color=never /backup/2 | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'
}

@test "backup single" {

  run docker compose exec -T volumerize backup 1
  assert_success

  run echo $(docker compose exec -T volumerize bash -c "ls --color=never /backup/1 | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

  run docker compose exec -T volumerize backup 2
  assert_success

  run echo $(docker compose exec -T volumerize bash -c "ls --color=never /backup/2 | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

}

@test "jobber" {

  run docker compose exec -T volumerize jobber test VolumerizeBackupJob1
  assert_success

  run echo $(docker compose exec -T volumerize bash -c "ls --color=never /backup/1 | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

  run docker compose exec -T volumerize jobber test VolumerizeBackupJob2
  assert_success

  run echo $(docker compose exec -T volumerize bash -c "ls --color=never /backup/2 | grep -Ec \"duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)\"")
  assert_output '3'

}

@test "jobber restore" {

  run docker compose exec -T volumerize jobber test VolumerizeBackupJob1
  assert_success
  run docker compose exec -T volumerize jobber test VolumerizeBackupJob2
  assert_success

  # Corrupt data to simulate necessity of restore
  run docker compose exec -T volumerize bash -c 'echo wrong | cat > /source/1/test.txt'
  assert_success
  run docker compose exec -T volumerize bash -c 'echo wrong | cat > /source/2/test.txt'
  assert_success
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_drop_table mariadb1
    assert_success
    run mysql_drop_table mariadb2
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_drop_collection mongodb1
    assert_success
    run mongo_get_values mongodb1
    refute_output
    run mongo_drop_collection mongodb2
    assert_success
    run mongo_get_values mongodb2
    refute_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_drop_table postgres1
    assert_success
    run postgres_drop_table postgres2
    assert_success
  fi

  run docker compose exec -T volumerize restore 1
  assert_success

  run docker compose exec -T volumerize restore 2
  assert_success

  run docker compose exec -T volumerize cat /source/1/test.txt
  assert_success
  assert_output --partial test
  run docker compose exec -T volumerize cat /source/2/test.txt
  assert_success
  assert_output --partial test
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_check_values mariadb1
    assert_success
    run mysql_check_values mariadb2
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_get_values mongodb1
    assert_success
    assert_output
    run mongo_get_values mongodb2
    assert_success
    assert_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_check_values postgres1
    assert_success
    run postgres_check_values postgres2
    assert_success
  fi

}

@test "restore all" {

  run docker compose exec -T volumerize backup
  assert_success
  assert_output

  run docker compose exec -T volumerize bash -c 'echo wrong | cat > /source/1/test.txt'
  assert_success
  run docker compose exec -T volumerize bash -c 'echo wrong | cat > /source/2/test.txt'
  assert_success
  # Corrupt data to simulate necessity of restore
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_drop_table mariadb1
    assert_success
    run mysql_drop_table mariadb2
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_drop_collection mongodb1
    assert_success
    run mongo_get_values mongodb1
    refute_output
    run mongo_drop_collection mongodb2
    assert_success
    run mongo_get_values mongodb2
    refute_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_drop_table postgres1
    assert_success
    run postgres_drop_table postgres2
    assert_success
  fi

  run docker compose exec -T volumerize restore
  assert_success

  # Validate that backup was restored
  run docker compose exec -T volumerize cat /source/1/test.txt
  assert_success
  assert_output --partial test
  run docker compose exec -T volumerize cat /source/2/test.txt
  assert_success
  assert_output --partial test
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_check_values mariadb1
    assert_success
    run mysql_check_values mariadb2
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_get_values mongodb1
    assert_success
    assert_output
    run mongo_get_values mongodb2
    assert_success
    assert_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_check_values postgres1
    assert_success
    run postgres_check_values postgres2
    assert_success
  fi

}

@test "restore single" {

  run docker compose exec -T volumerize backup
  assert_success
  assert_output

  # Corrupt data to simulate necessity of restore
  run docker compose exec -T volumerize bash -c 'echo wrong | cat > /source/1/test.txt'
  assert_success
  run docker compose exec -T volumerize bash -c 'echo wrong | cat > /source/2/test.txt'
  assert_success
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_drop_table mariadb1
    assert_success
    run mysql_drop_table mariadb2
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_drop_collection mongodb1
    assert_success
    run mongo_get_values mongodb1
    refute_output
    run mongo_drop_collection mongodb2
    assert_success
    run mongo_get_values mongodb2
    refute_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_drop_table postgres1
    assert_success
    run postgres_drop_table postgres2
    assert_success
  fi

  run docker compose exec -T volumerize restore 1
  assert_success

  run docker compose exec -T volumerize restore 2
  assert_success


  run docker compose exec -T volumerize cat /source/1/test.txt
  assert_success
  assert_output --partial test
  run docker compose exec -T volumerize cat /source/2/test.txt
  assert_success
  assert_output --partial test
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    run mysql_check_values mariadb1
    assert_success
    run mysql_check_values mariadb2
    assert_success
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    run mongo_get_values mongodb1
    assert_success
    assert_output
    run mongo_get_values mongodb2
    assert_success
    assert_output
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    run postgres_check_values postgres1
    assert_success
    run postgres_check_values postgres2
    assert_success
  fi

}

teardown() {
  docker compose --ansi never exec -T volumerize bash -c 'rm -rf /volumerize-cache/**/* /backup/**/* /source/**/*'
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Drop Table
    mysql_drop_table mariadb1
    mysql_drop_table mariadb2
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Drop collection contents
    mongo_drop_collection mongodb1
    mongo_drop_collection mongodb2
  elif [ $TEST_IMAGE_TYPE == postgres ]; then
    postgres_drop_table postgres1
    postgres_drop_table postgres2
  fi
  docker compose --ansi never logs
}

teardown_file() {
  docker compose --ansi never down -v
}

function wait_until_running() {
  local service=$1
  local timeout=$2
  local first_line=$3
  local last_line=$4

  local wait_time=0

  until docker compose --no-ansi logs $service | grep "${first_line}" || [ $wait_time -ge $timeout ];
  do
    echo "waiting for ${service} to be up and running"
    wait_time=$(( $wait_time + 1 ))
    sleep 1
  done
  echo "initialization done, waiting for ${service} to start"
  # Wait unitl mysql can handle connections
  until docker compose --no-ansi logs --tail 5 $service | grep "${last_line}" || [ $wait_time -ge $timeout ];
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

mysql_default_command="mariadb -u ${mysql_user} --password=${mysql_pwd} somedatabase -e "

function mysql_initialize_db() {
  local service=$1
  eval docker compose exec -T $service ${mysql_default_command} "\"create table ${mysql_table_name}(${mysql_column_name} varchar(100))\""
  eval docker compose exec -T $service ${mysql_default_command} "\"insert into ${mysql_table_name} (${mysql_column_name}) values ('${mysql_value}')\""
}


function mysql_drop_table() {
  local service=$1
  eval docker compose exec -T $service ${mysql_default_command} "\"drop table ${mysql_table_name}\""
}

function mysql_get_values() {
  local service=$1
  eval docker compose exec -T $service ${mysql_default_command} "\"select * from ${mysql_table_name}\""
}

function mysql_check_values() {
  local actual=$( mysql_get_values $@ | tr -d '\r' )
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

mongo_default_command="mongo --quiet -u ${mongo_user} -p ${mongo_pwd} "

function mongo_initialize_db() {
  local service=$1
  eval docker compose exec -T $service ${mongo_default_command} "\"/scripts/init.js\""
}


function mongo_drop_collection() {
  local service=$1
  eval docker compose exec -T $service ${mongo_default_command} "\"/scripts/drop.js\""
}

function mongo_get_values() {
  local service=$1
  eval docker compose exec -T $service ${mongo_default_command} "\"/scripts/find.js\""
}

postgres_table_name=test
postgres_column_name=test
postgres_database=postgres
postgres_value=test
postgres_user=postgres
postgres_pwd=1234

postgres_compose_exec="docker compose exec -T -e PGPASSWORD=${postgres_pwd}"
postgres_default_command="psql -qtA --username=${postgres_user} ${postgres_database} -c "

function postgres_initialize_db() {
  local service=$1
  eval ${postgres_compose_exec} ${service} ${postgres_default_command} "\"create table ${postgres_table_name}(${postgres_column_name} varchar(100))\""
  eval ${postgres_compose_exec} ${service} ${postgres_default_command} "\"insert into ${postgres_table_name} (${postgres_column_name}) values ('${postgres_value}')\""
}


function postgres_drop_table() {
  local service=$1
  eval ${postgres_compose_exec} ${service} ${postgres_default_command} "\"drop table ${postgres_table_name}\""
}

function postgres_get_values() {
  local service=$1
  eval ${postgres_compose_exec} ${service} ${postgres_default_command} "\"select * from ${postgres_table_name}\""
}

function postgres_check_values() {
  local actual=$( postgres_get_values $@ | tr -d '\r' )
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
