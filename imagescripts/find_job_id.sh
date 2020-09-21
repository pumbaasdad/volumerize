#!/bin/bash

# This script needs to be sourced without arguments to work correctly
# It will remove the first argument from the argument list if it is a number and saves it in the JOB_ID variable

if [ ! -z "${1##*[!0-9]*}" ]; then
  export JOB_ID=$1
  shift
fi
