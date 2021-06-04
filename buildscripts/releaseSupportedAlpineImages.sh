#!/bin/bash -x

set -o errexit    # abort script at first error

function pushImage() {
  local tagname=$1
  local repository=$2

  docker push fekide/volumerize:$tagname
}

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
readonly PUSH_REPOSITORY=$1
source $CUR_DIR/release.sh

for IMAGE_TYPE in "" mongodb mysql postgres mongodb-mysql mongodb-postgres mongodb-mysql-postgres mysql-postgres; do
  printf '%b\n' ":: Release ${IMAGE_TYPE:-default} image...."
  release
  pushImage $IMAGE_TAG $PUSH_REPOSITORY
done
