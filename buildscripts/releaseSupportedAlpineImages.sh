#!/bin/bash -x

set -o errexit    # abort script at first error

function pushImage() {
  local tagname=$1
  local repository=$2

  echo  docker push fekide/volumerize:$tagname
}

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
readonly PUSH_REPOSITORY=$1

printf '%b\n' ":: Release default image...."
source $CUR_DIR/release.sh

pushImage $IMAGE_TAG $PUSH_REPOSITORY


export IMAGE_TYPE=mongodb
printf '%b\n' ":: Release ${IMAGE_TYPE} image...."
source $CUR_DIR/release.sh

pushImage $IMAGE_TAG $PUSH_REPOSITORY


export IMAGE_TYPE=mysql
printf '%b\n' ":: Release ${IMAGE_TYPE} image...."
source $CUR_DIR/release.sh

pushImage $IMAGE_TAG $PUSH_REPOSITORY