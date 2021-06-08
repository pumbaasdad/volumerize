#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

function discoverDatabases() {
  local x
  for ((x = 1; ; x++)); do
    local VARIABLE_DB_HOST="VOLUMERIZE_POSTGRES_HOST${x}"
    if [ ! -n "${!VARIABLE_DB_HOST}" ]; then
      break
    else
      DB_COUNT=$x
    fi
  done
}

function prepareDBConfiguration() {
  local jobNumber=$DB_ID
  if [ "${jobNumber}" == 0 ]; then
    jobNumber=
  fi
  local jobType=${1:-"unknown"}
  local VARIABLE_DB_HOST="VOLUMERIZE_POSTGRES_HOST${jobNumber}"
  local VARIABLE_DB_PASSWORD="VOLUMERIZE_POSTGRES_PASSWORD${jobNumber}"
  local VARIABLE_DB_USERNAME="VOLUMERIZE_POSTGRES_USERNAME${jobNumber}"
  local VARIABLE_DB_PORT="VOLUMERIZE_POSTGRES_PORT${jobNumber}"
  local VARIABLE_DB_SOURCE="VOLUMERIZE_POSTGRES_SOURCE${jobNumber}"
  local VARIABLE_DB_DATABASE="VOLUMERIZE_POSTGRES_DATABASE${jobNumber}"
  
  file_env ${VARIABLE_DB_PASSWORD}
  if [ -n "${!VARIABLE_DB_SOURCE}" ]; then
    VARIABLE_DB_SOURCE=${!VARIABLE_DB_SOURCE}
  else
    VARIABLE_DB_SOURCE="VOLUMERIZE_SOURCE"
  fi
  if [ -z "${!VARIABLE_DB_PORT}" ]; then
    local ${VARIABLE_DB_PORT}=5432
  fi
  if [ -n "${JOB_ID}" ] && [ "VOLUMERIZE_SOURCE${JOB_ID}" != "${VARIABLE_DB_SOURCE}" ]; then
    echo "INFO: Database ${jobNumber} skipped because the running job does not correspond to its source destination"
    return 1
  fi
  check_env ${jobType} ${VARIABLE_DB_HOST} ${VARIABLE_DB_PASSWORD} ${VARIABLE_DB_USERNAME} ${VARIABLE_DB_PORT} ${VARIABLE_DB_SOURCE} ${VARIABLE_DB_DATABASE}

  VOLUMERIZE_DB_HOST=${!VARIABLE_DB_HOST}
  VOLUMERIZE_DB_PASSWORD=${!VARIABLE_DB_PASSWORD}
  VOLUMERIZE_DB_USERNAME=${!VARIABLE_DB_USERNAME}
  VOLUMERIZE_DB_PORT=${!VARIABLE_DB_PORT}
  VOLUMERIZE_DB_SOURCE=${!VARIABLE_DB_SOURCE}
  VOLUMERIZE_DB_DATABASE=${!VARIABLE_DB_DATABASE}
}

function prepareDatabase() {
  local jobNumber=$DB_ID
  local jobType=$POSTGRES_JOB_TYPE
  HOST_VARIABLE="VOLUMERIZE_POSTGRES_HOST${jobNumber}"
  if [ -n "${!HOST_VARIABLE}" ]; then
    prepareDBConfiguration $jobType
  else
    return 1
  fi
}

function databaseLoop() {
  local jobcount=$DB_COUNT
  local counter
  for ((counter = 1; counter <= $jobcount; counter++)); do
    local returnCode=0
    DB_ID=$counter
    prepareDatabase "$@" || returnCode=$? && true ;
    if [ "$returnCode" -gt 0 ]; then
      echo "WARN: Variables could not be prepared for the database id ${counter}, skipping ..."
    else
      databaseJob "$@"
    fi
  done
}

function databaseExecution() {
  if [ -n "${VOLUMERIZE_POSTGRES_HOST}" ] || [ -n "${DB_ID}" ]; then
    prepareDatabase "$@" || returnCode=$? && true ;
    if [ "$returnCode" -gt 0 ]; then
      echo "WARN: Variables could not be prepared for the database id ${DB_ID:-0}, skipping ..."
    else
      databaseJob "$@"
    fi
  elif [ -n "${DB_COUNT}" ]; then
    databaseLoop "$@"
  fi
}

function databaseJob() {
  echo "Fail: You need to override function 'databaseJob' after sourcing this script"
  exit 1
}

discoverDatabases
