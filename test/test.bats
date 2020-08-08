#!/usr/bin/env ./test/libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup() {
  docker version
  docker-compose version
  export COMPOSE_FILE=docker-compose.yml
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

teardown() {
  docker-compose down -v
}
