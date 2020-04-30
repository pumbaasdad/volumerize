#!/bin/bash

set -o errexit

readonly JOBBER_SCRIPT_DIR=$VOLUMERIZE_HOME

source $CUR_DIR/base.sh

JOBBER_CRON_SCHEDULE='0 0 4 * * *'

if [ -n "${VOLUMERIZE_JOBBER_TIME}" ]; then
  JOBBER_CRON_SCHEDULE=${VOLUMERIZE_JOBBER_TIME}
fi

stdout_failure_sink=$'\n'"      - *stdoutFailureSink"

JOB_NAME1=VolumerizeBackupJob
JOB_COMMAND1=${JOBBER_SCRIPT_DIR}/periodicBackup
JOB_TIME1=$JOBBER_CRON_SCHEDULE
JOB_ON_ERROR1=Continue
JOB_NOTIFY_ERR1=${JOBBER_NOTIFY_ERR1:-$stdout_failure_sink}
JOB_NOTIFY_FAIL1=${JOBBER_NOTIFY_FAIL1:-$stdout_failure_sink}

readonly configfile="/root/.jobber"

function pipeEnvironmentVariables() {
  local environmentfile="/etc/profile.d/jobber.sh"
  cat > ${environmentfile} <<EOF
  #!/bin/sh
EOF
  sh -c export >> ${environmentfile}
  sed -i.bak '/^export [a-zA-Z0-9_]*:/d' ${environmentfile}
}

if [ ! -f "${configfile}" ]; then
  touch ${configfile}

  cat >> ${configfile} <<EOF
version: 1.4

resultSinks:
  - &stdoutFailureSink
    type: stdout
    data:
      - stdout
      - stderr

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
    it_job_notify_error=${!VAR_JOB_NOTIFY_ERR:-$stdout_failure_sink}
    it_job_notify_failure=${!VAR_JOB_NOTIFY_FAIL:-$stdout_failure_sink}

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

cat ${configfile}
