#!/bin/bash -x

set -o errexit    # abort script at first error

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source $CUR_DIR/release.sh
source $CUR_DIR/testImage.sh

for IMAGE_TYPE in "" mongodb mysql postgres; do
  export IMAGE_TYPE
  printf '%b\n' ":: Testing ${IMAGE_TYPE:-default} image...."
  release
  testImage $IMAGE_TAG $IMAGE_TYPE
done
