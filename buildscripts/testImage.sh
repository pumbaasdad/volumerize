#!/bin/bash -x

set -o errexit    # abort script at first erro

function testImage () {
  export TEST_IMAGE_TAG=${1:-${IMAGE_TAG:-latest}}
  export TEST_IMAGE_TYPE=${2:-${IMAGE_TYPE:-default}}
  REPORT_DIR=report

  ./test/libs/bats-core/bin/bats --formatter junit test || TEST_RETURN_CODE=$? && true

  if [ ! -d "${REPORT_DIR}/${TEST_IMAGE_TYPE}"  ]; then
    mkdir -p ${REPORT_DIR}/${TEST_IMAGE_TYPE}
  fi
  mv *.bats.xml ${REPORT_DIR}/${TEST_IMAGE_TYPE}/

  return ${TEST_RETURN_CODE:-0}
}