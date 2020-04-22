#!/bin/bash -x

#------------------
# CONTAINER VARIABLES
#------------------
export IMAGE_VERSION=${IMAGE_VERSION:-latest}
export BUILD_BRANCH=${BUILD_BRANCH:-$(git branch | grep -e "^*" | cut -d' ' -f 2)}
