#!/usr/bin/env ./test/libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup() {
  docker version
  docker-compose version
  export COMPOSE_FILE=${BATS_TEST_DIRNAME}/docker-compose.yml
  docker-compose up -d
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

@test "remove n backups" {
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
  docker-compose down -v
}
