#!/usr/bin/env ./test/libs/bats-core/bin/bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

setup() {
  docker-compose version
  export COMPOSE_FILE=test/docker-compose.yml
  docker-compose up -d
}

@test "manual backup" {

  run docker-compose exec volumerize backup
  assert_success

  run docker-compose exec -w "/" volumerize ls backup
  assert_output "test"

}

teardown() {
  docker-compose down
}
