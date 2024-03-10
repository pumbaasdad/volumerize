#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

DUPLICITY_COMMAND="duplicity"

DUPLICITY_OPTIONS=""

DUPLICITY_MODE=""

JOB_COUNT=

function discoverJobs() {
  local x
  for (( x=1; ; x++ ))
  do
    JOB_VARIABLE="VOLUMERIZE_SOURCE${x}"
    if [ ! -n "${!JOB_VARIABLE}" ]; then
      break
    else
      JOB_COUNT=$x
    fi
  done
}

DUPLICITY_JOB_COMMAND=
DUPLICITY_JOB_OPTIONS=
VOLUMERIZE_JOB_SOURCE=
VOLUMERIZE_JOB_TARGET=
VOLUMERIZE_JOB_INCLUDES=
VOLUMERIZE_JOB_EXCLUDES=

function prepareJobCommand() {
  local jobNumber=$1
  DUPLICITY_JOB_COMMAND=$DUPLICITY_COMMAND
  file_env "PASSPHRASE"
  file_env "VOLUMERIZE_GPG_PRIVATE_KEY"
  file_env "FTP_PASSWORD"
  local CACHE_VARIABLE="VOLUMERIZE_CACHE${jobNumber}"
  if [ -n "${!CACHE_VARIABLE}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --archive-dir=${!CACHE_VARIABLE}"
  else
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --archive-dir=${VOLUMERIZE_CACHE}/${jobNumber}"
  fi
  if [ -n "${VOLUMERIZE_DUPLICITY_OPTIONS}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" "${VOLUMERIZE_DUPLICITY_OPTIONS}
  fi
  if [ ! -n "${PASSPHRASE}" ] && [ ! -n "${VOLUMERIZE_GPG_PUBLIC_KEY}" ] && [ ! -n "${VOLUMERIZE_GPG_PRIVATE_KEY}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --no-encryption"
  fi
  if [ -n "${GPG_KEY_ID}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --gpg-options --trust-model=always --encrypt-key ${GPG_KEY_ID}"
  fi
  if [ -n "${VOLUMERIZE_FULL_IF_OLDER_THAN}" ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --full-if-older-than ${VOLUMERIZE_FULL_IF_OLDER_THAN}"
  fi
  if [ "${VOLUMERIZE_ASYNCHRONOUS_UPLOAD}" = 'true' ]; then
    DUPLICITY_JOB_OPTIONS=$DUPLICITY_JOB_OPTIONS" --asynchronous-upload"
  fi
}

function prepareJobConfiguration() {
  local jobNumber=$1
  local VARIABLE_SOURCE="VOLUMERIZE_SOURCE${jobNumber}"
  local VARIABLE_TARGET="VOLUMERIZE_TARGET${jobNumber}"
  local VARIABLE_RESTORE="VOLUMERIZE_RESTORE${jobNumber}"
  local VARIABLE_REPLICATE_TARGET="VOLUMERIZE_REPLICATE${jobNumber}"
  if [ -n "${!VARIABLE_SOURCE}" ]; then
    VOLUMERIZE_JOB_SOURCE=${!VARIABLE_SOURCE}
  else
    VOLUMERIZE_JOB_SOURCE=
  fi

  file_env ${VARIABLE_TARGET}
  if [ -n "${!VARIABLE_TARGET}" ]; then
    VOLUMERIZE_JOB_TARGET=${!VARIABLE_TARGET}
  else
    VOLUMERIZE_JOB_TARGET=
  fi

  if [ -n "${!VARIABLE_RESTORE}" ]; then
    VOLUMERIZE_JOB_RESTORE=${!VARIABLE_RESTORE}
  else
    VOLUMERIZE_JOB_RESTORE=${!VARIABLE_SOURCE}
  fi

  file_env ${VARIABLE_REPLICATE_TARGET}
  if [ -n "${!VARIABLE_REPLICATE_TARGET}" ]; then
    VOLUMERIZE_JOB_REPLICATE_TARGET=${!VARIABLE_REPLICATE_TARGET}
  else
    VOLUMERIZE_JOB_REPLICATE_TARGET=
  fi
}

function resolveJobIncludes() {
  local jobNumber=$1
  local x
  local VARIABLE_INCLUDE
  VOLUMERIZE_JOB_INCLUDES=
  for (( x=1; ; x++ ))
  do
    VARIABLE_INCLUDE="VOLUMERIZE_INCLUDE${jobNumber}_${x}"
    if [ ! -n "${!VARIABLE_INCLUDE}" ]; then
      break
    fi
    VOLUMERIZE_JOB_INCLUDES=$VOLUMERIZE_JOB_INCLUDES" --include "${!VARIABLE_INCLUDE}
  done
}

function resolveJobExcludes() {
  local jobNumber=$1
  local x
  local VARIABLE_EXCLUDE
  VOLUMERIZE_JOB_EXCLUDES=
  for (( x=1; ; x++ ))
  do
    VARIABLE_EXCLUDE="VOLUMERIZE_EXCLUDE${jobNumber}_${x}"
    if [ ! -n "${!VARIABLE_EXCLUDE}" ]; then
      break
    fi
    VOLUMERIZE_JOB_EXCLUDES=$VOLUMERIZE_JOB_EXCLUDES" --exclude "${!VARIABLE_EXCLUDE}
  done
}

function prepareJob() {
  local jobNumber=$1
  JOB_VARIABLE="VOLUMERIZE_SOURCE${jobNumber}"
  if [ -n "${!JOB_VARIABLE}" ]; then
    prepareJobCommand $jobNumber
    prepareJobConfiguration $jobNumber
    resolveJobIncludes $jobNumber
    resolveJobExcludes $jobNumber
  fi
}

function commandLoop() {
  local jobcount=$JOB_COUNT
  local counter;

  for (( counter=1; counter<=$jobcount; counter++ ))
  do
    JOB_ID=$counter
    prepareJob $JOB_ID
    commandJob "$@"
  done
}

function commandExecution() {
  if [ -n "${VOLUMERIZE_SOURCE}" ] || [ -n "${JOB_ID}" ]; then
    prepareJob $JOB_ID
    commandJob "$@"
  elif [ -n "${JOB_COUNT}" ]; then
    commandLoop "$@"
  fi
}

function commandJob() {
  echo "Fail: You need to override function 'commandJob' after sourcing this script"
  exit 1
}

discoverJobs
