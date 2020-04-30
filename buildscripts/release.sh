#!/bin/bash -x

#------------------
# CONTAINER VARIABLES
#------------------
export IMAGE_VERSION=${IMAGE_VERSION:-${CIRCLE_TAG:-latest}}
export IMAGE_TYPE=${IMAGE_TYPE}

if [ -z $IMAGE_TYPE ]; then
	export IMAGE_TAG=${IMAGE_VERSION}
else
	if [ $IMAGE_VERSION = "latest" ]; then
		export IMAGE_TAG=${IMAGE_TYPE}
	else
		export IMAGE_TAG=${IMAGE_VERSION}-${IMAGE_TYPE}
	fi
fi

export BUILD_BRANCH=${BUILD_BRANCH:-${CIRCLE_BRANCH:-$(git branch | grep -e "^*" | cut -d' ' -f 2)}}
