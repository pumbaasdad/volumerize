#!/usr/bin/env ./test/libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup_file() {
  docker version
  docker-compose version
  export COMPOSE_FILE=${BATS_TEST_DIRNAME}/compose-files/${TEST_IMAGE_TYPE:-default}.yml
  docker-compose --no-ansi up -d
  if [ $TEST_IMAGE_TYPE == mysql ]; then
    # Wait for database initialisation
    wait_time=0
    timeout=60
    until docker-compose --no-ansi logs mariadb | grep "MySQL init process done. Ready for start up." || [ $wait_time -ge 120 ];
    do
      echo "waiting for mysql to be up and running"
      wait_time=$(( $wait_time + 1 ))
      sleep 1
    done
    # Wait unitl mysql can handle connections
    wait_time=0
    until docker-compose --no-ansi logs --tail 5 mariadb | grep "mysqld: ready for connections." || [ $wait_time -ge 60 ];
    do
      echo "waiting for mysql to be up and running"
      wait_time=$(( $wait_time + 1 ))
      sleep 1
    done
    if [ $wait_time -ge 60 ]; then
      echo "mysql took too long to initialize"
      return 1
    fi
  elif [ $TEST_IMAGE_TYPE == mongodb ]; then
    # Wait for database initialisation
    wait_time=0
    timeout=60
    until docker-compose --no-ansi logs mongodb | grep "MongoDB init process complete; ready for start up." || [ $wait_time -ge 120 ];
    do
      echo "waiting for mongodb to be up and running"
      wait_time=$(( $wait_time + 1 ))
      sleep 1
    done
    # Wait unitl mysql can handle connections
    wait_time=0
    until docker-compose --no-ansi logs --tail 5 mongodb | grep "Waiting for connections" || [ $wait_time -ge 60 ];
    do
      echo "waiting for mongodb to be up and running"
      wait_time=$(( $wait_time + 1 ))
      sleep 1
    done
    if [ $wait_time -ge 60 ]; then
      echo "mongodb took too long to initialize"
      return 1
    fi
  fi
}


@test "version" {

  run docker-compose exec volumerize duplicity -V
  assert_success

}

@test "manual backup" {

  run docker-compose exec volumerize backup
  assert_success

  run echo $(docker-compose exec volumerize ls --color=never /backup | grep -Ec "duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)")
  assert_output '3'

}

@test "keep n backups" {
  for i in {1..5}
  do
    run docker-compose exec -e REMOVE_ALL_BUT_N_FULL=3 volumerize backupFull
    assert_success
    assert_output
    sleep 1
  done

  run echo $(docker-compose exec volumerize ls --color=never /backup | grep -Ec "duplicity-full(-signatures)?\.[0-9A-Z]{16}\.(manifest|(vol1\.difftar|sigtar)\.gz)")
  assert_output '9'

}

@test "restore" {
  run docker-compose exec volumerize backup
  assert_success
  assert_output

  run docker-compose exec volumerize restore
  assert_success

}

teardown() {
  docker-compose --no-ansi exec volumerize rm -rf /volumerize-cache/* /backup/*
  docker-compose --no-ansi logs
}

teardown_file() {
  docker-compose --no-ansi down -v
}
