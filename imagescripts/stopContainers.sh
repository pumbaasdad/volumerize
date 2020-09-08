#!/bin/bash

set -e

[[ ${DEBUG} == true ]] && set -x

source /opt/volumerize/docker.sh

if [ -n "${VOLUMERIZE_CONTAINERS}" ]; then
  stopContainers "${VOLUMERIZE_CONTAINERS}"
fi
