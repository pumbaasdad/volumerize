#!/bin/bash -x

set -o errexit    # abort script at first error

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source $CUR_DIR/release.sh
source $CUR_DIR/testImage.sh

printf '%b\n' ":: Testing default image...."
release
testImage $IMAGE_TAG

export IMAGE_TYPE=mongodb
printf '%b\n' ":: Testing ${IMAGE_TYPE} image...."
release
testImage $IMAGE_TAG $IMAGE_TYPE

export IMAGE_TYPE=mysql
printf '%b\n' ":: Testing ${IMAGE_TYPE} image...."
release
testImage $IMAGE_TAG $IMAGE_TYPE
