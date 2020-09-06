#!/bin/bash -x

#------------------
# CONTAINER VARIABLES
#------------------
function release() {
  local BUILD_VERSION=${BUILD_BRANCH:-${CIRCLE_BRANCH:-$(git branch | grep -e "^*" | cut -d' ' -f 2)}}
  if [ $BUILD_VERSION == master ]; then
    BUILD_VERSION=latest
  fi
  local IMAGE_VERSION=${IMAGE_VERSION:-${CIRCLE_TAG:-$BUILD_VERSION}}

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
