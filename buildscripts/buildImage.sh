#!/bin/bash -x

set -o errexit    # abort script at first error

function buildImage() {
  local tagname=$1
  local path=${2:-"."}
  shift 2
  docker build --no-cache -t fekide/volumerize:$tagname $@ $path
}
