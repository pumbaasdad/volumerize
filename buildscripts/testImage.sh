#!/bin/bash -x

set -o errexit    # abort script at first erro

function testImage () {
  export TEST_IMAGE_TAG=${1:-${IMAGE_TAG:-latest}}
  export TEST_IMAGE_TYPE=${2:-${IMAGE_TYPE:-default}}
  REPORT_DIR=report

  if [ ! -d "${REPORT_DIR}/${TEST_IMAGE_TYPE}"  ]; then
    mkdir -p ${REPORT_DIR}/${TEST_IMAGE_TYPE}
  fi

  ./test/libs/bats-core/bin/bats --report-formatter junit -o ${REPORT_DIR}/${TEST_IMAGE_TYPE} test

}