#!/bin/bash -x

set -o errexit    # abort script at first erro

export IMAGE_VERSION=$1
REPORT_DIR=report

./test/libs/bats-core/bin/bats --formatter junit test || TEST_RETURN_CODE=$? && true

if [ ! -d "${REPORT_DIR}"  ]; then
	mkdir ${REPORT_DIR}
fi
mv *.bats.xml ${REPORT_DIR}

exit ${TEST_RETURN_CODE:-0}