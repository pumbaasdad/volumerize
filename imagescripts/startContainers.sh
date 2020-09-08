#!/bin/bash

set -e

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/docker.sh

if [ -n "${VOLUMERIZE_CONTAINERS}" ]; then
  startContainers "${VOLUMERIZE_CONTAINERS}"
fi
