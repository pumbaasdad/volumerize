#!/bin/bash

##
# @private
# Executed if a variable is not set or is empty string
# @param1 - Name of the failed environment variable
##
function _check_env_failed() {
  echo "Environment variable $1 is not set."
  echo "Environment variables failed, exit 1"
  exit 1
}

##
# @private
# Executed if a variable is setted
# @param1 - Name of the environment variable
##
function _check_env_ok() {
  echo "Env var $1 ok."
}

##
# Use it to check if environment variables are set
# @param1      - Name of the context
# @param2 to ∞ - Environment variables to check
##
function check_env() {
  echo "Checking environment variables for $1."
  shift

  for e_var in ""$@""; do

    # Check if env var is setted, if not raise error
    if [ "${!e_var}" = "" ]; then
      _check_env_failed $e_var
    else
      _check_env_ok $e_var
    fi

  done
  echo "Environment variables ok."
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo "Both $var and $fileVar are set (but are exclusive)"
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(<"${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

function pipeEnvironmentVariables() {
  local environmentfile=$1
  cat > ${environmentfile} <<EOF
  #!/bin/sh
EOF
  sh -c export >> ${environmentfile}
}
