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


export IMAGE_TYPE=mongodb
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release
export MONGODB_TAG=$IMAGE_TAG

buildImage $IMAGE_TAG ./prepost_strategies/mongodb --build-arg BASE_IMAGE_TAG


export IMAGE_TYPE=mysql
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release
export MYSQL_TAG=$IMAGE_TAG

buildImage $IMAGE_TAG ./prepost_strategies/mysql --build-arg BASE_IMAGE_TAG


export IMAGE_TYPE=postgres
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release

buildImage $IMAGE_TAG ./prepost_strategies/postgres --build-arg BASE_IMAGE_TAG


export IMAGE_TYPE=mongodb-mysql
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release
export MONGODB_MYSQL_TAG=$IMAGE_TAG

buildImage $IMAGE_TAG ./prepost_strategies/mysql --build-arg BASE_IMAGE_TAG=$MONGODB_TAG


export IMAGE_TYPE=mongodb-postgres
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release

buildImage $IMAGE_TAG ./prepost_strategies/postgres --build-arg BASE_IMAGE_TAG=$MONGODB_TAG


export IMAGE_TYPE=mongodb-mysql-postgres
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release

buildImage $IMAGE_TAG ./prepost_strategies/postgres --build-arg BASE_IMAGE_TAG=$MONGODB_MYSQL_TAG


export IMAGE_TYPE=mysql-postgres
printf '%b\n' ":: Building ${IMAGE_TYPE} image...."
release

buildImage $IMAGE_TAG ./prepost_strategies/postgres --build-arg BASE_IMAGE_TAG=$MYSQL_TAG


printf '%b\n' ":: Built images"
docker image ls fekide/volumerize