#!/bin/bash -x

set -o errexit    # abort script at first error
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source $CUR_DIR/buildImage.sh 
source $CUR_DIR/release.sh

# Setting environment variables

printf '%b\n' ":: Building default image...."
release
export BASE_IMAGE_TAG=$IMAGE_TAG

buildImage $IMAGE_TAG .


printf '%b\n' ":: Building mongodb image...."
export IMAGE_TYPE=mongodb
release

buildImage $IMAGE_TAG ./prepost_strategies/mongodb --build-arg BASE_IMAGE_TAG


printf '%b\n' ":: Building mysql image...."
export IMAGE_TYPE=mysql
release

buildImage $IMAGE_TAG ./prepost_strategies/mysql --build-arg BASE_IMAGE_TAG


printf '%b\n' ":: Building postgresql image...."
export IMAGE_TYPE=postgres
release

buildImage $IMAGE_TAG ./prepost_strategies/postgres --build-arg BASE_IMAGE_TAG


printf '%b\n' ":: Built images"
docker image ls fekide/volumerize