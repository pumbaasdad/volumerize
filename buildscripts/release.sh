#!/bin/bash -x

#------------------
# CONTAINER VARIABLES
#------------------

slugify () {
  echo "$1" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9\.]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z
}

function release() {
  local BUILD_VERSION=${BUILD_BRANCH:-${GITHUB_REF_NAME:-$(git branch | grep -e "^*" | cut -d' ' -f 2)}}
  if [ $BUILD_VERSION == master ]; then
    BUILD_VERSION=latest
  fi
  local IMAGE_VERSION=$(slugify ${IMAGE_VERSION:-$BUILD_VERSION})

  if [ -z $IMAGE_TYPE ]; then
    export IMAGE_TAG=${IMAGE_VERSION}
  else
    if [ $IMAGE_VERSION = "latest" ]; then
      export IMAGE_TAG=${IMAGE_TYPE}
    else
      export IMAGE_TAG=${IMAGE_VERSION}-${IMAGE_TYPE}
    fi
  fi

}
