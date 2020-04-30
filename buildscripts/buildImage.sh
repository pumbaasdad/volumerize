#!/bin/bash -x

set -o errexit    # abort script at first error

function buildImage() {
  local tagname=$1
  local path=${2:-"."}
  local branch=$BUILD_BRANCH
  docker build --no-cache -t fekide/volumerize:$tagname $path
}

buildImage $1 $2
