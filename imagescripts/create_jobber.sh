#!/bin/bash

set -o errexit

readonly JOBBER_SCRIPT_DIR=$VOLUMERIZE_HOME
readonly configfile="$(echo ~)/.jobber"


if [[ "$JOBBER_DISABLE" == true ]]; then
  if [ ! -f "${configfile}" ]; then
    # create empty jobber config
    cat > "${configfile}" <<EOF
version: 1.4
jobs:
EOF
  else
    echo "Jobber was configured to be disabled, but cannot be disabled because there already is a config file at '$(echo ~)/.jobber'. Please delete/unmount to disable jobber"
  fi

elif [[ -n "$JOBBER_CUSTOM" ]]; then

  returnCode=0
  # Copy the file at location CUSTOM_JOBBER to the root jobs
  cp $JOBBER_CUSTOM $configfile || returnCode=$? && true

  if [ ${returnCode} -gt 0 ]; then
    echo "failed to copy $CUSTOM_JOBBER to $configfile. Make sure this is not a problem!"
  fi

else
  # Create a jobber file dynamically

  source $CUR_DIR/base.sh

  JOBBER_SCHEDULE=${VOLUMERIZE_JOBBER_TIME:-'0 0 4 * * *'}
  stdout_sink=$'\n'"      - *stdoutSink"
  apprise_notify_sink=$'\n'"      - *notifyApprise"

  job_count=${JOB_COUNT:-1}
  counter=

  for (( counter=1; counter<=$job_count; counter++ ))
  do
    # only set job id if there is more than one job
    job_id=
    if [ $job_count -gt 1 ]; then
      job_id=${counter}
    fi

    job_time="VOLUMERIZE_JOBBER_TIME${job_id}"

    # Verify if apprise urls exist, default first to both, then to global
    apprise_notify="APPRISE_NOTIFY${job_id}"
    apprise_notify=${!apprise_notify:-"APPRISE_NOTIFY"}
    apprise_notify_err="APPRISE_NOTIFY_ERR${job_id}"
    apprise_notify_err=${!apprise_notify_err:-apprise_notify}
    apprise_notify_fail="APPRISE_NOTIFY_FAIL${job_id}"
    apprise_notify_fail=${!apprise_notify_fail:-apprise_notify}


    declare "JOB_NAME${counter}"="VolumerizeBackupJob${job_id}"
    declare "JOB_COMMAND${counter}"="${JOBBER_SCRIPT_DIR}/periodicBackup ${job_id}"
    declare "JOB_TIME${counter}"="${!job_time:-${JOBBER_SCHEDULE}}"
    declare "JOB_ON_ERROR${counter}"="Continue"
    declare "JOB_NOTIFY_ERR${counter}"="${stdout_sink}${!apprise_notify_err:+$apprise_notify_sink}"
    declare "JOB_NOTIFY_FAIL${counter}"="${stdout_sink}${!apprise_notify_fail:+$apprise_notify_sink}"
  done




  if [ ! -f "${configfile}" ]; then
    touch ${configfile}

    cat >> ${configfile} <<EOF
version: 1.4

resultSinks:
  - &stdoutSink
    type: stdout
    data:
      - stdout
      - stderr
  - &notifyApprise
    type: program
    path: /opt/volumerize/notify_apprise.py

prefs:
  runLog:
    type: file
    path: /var/log/jobber-runs
    maxFileLen: 100m
    maxHistories: 2

jobs:

EOF
    for (( i = 1; ; i++ ))
    do
      VAR_JOB_ON_ERROR="JOB_ON_ERROR$i"
      VAR_JOB_NAME="JOB_NAME$i"
      VAR_JOB_COMMAND="JOB_COMMAND$i"
      VAR_JOB_TIME="JOB_TIME$i"
      VAR_JOB_NOTIFY_ERR="JOB_NOTIFY_ERR$i"
      VAR_JOB_NOTIFY_FAIL="JOB_NOTIFY_FAIL$i"

      if [ ! -n "${!VAR_JOB_NAME}" ]; then
        break
      fi

      it_job_on_error=${!VAR_JOB_ON_ERROR:-"Continue"}
      it_job_name=${!VAR_JOB_NAME}
      it_job_time=${!VAR_JOB_TIME}
      it_job_command=${!VAR_JOB_COMMAND}
      it_job_notify_error=${!VAR_JOB_NOTIFY_ERR:-$stdout_sink}
      it_job_notify_failure=${!VAR_JOB_NOTIFY_FAIL:-$stdout_sink}

      cat >> ${configfile} <<EOF
  ${it_job_name}:
    cmd: ${it_job_command}
    time: '${it_job_time}'
    onError: ${it_job_on_error}
    notifyOnError: ${it_job_notify_error}
    notifyOnFailure: ${it_job_notify_failure}

EOF
    done
  fi
fi

if [ -f ${configfile} ]; then
  cat ${configfile}
fi
