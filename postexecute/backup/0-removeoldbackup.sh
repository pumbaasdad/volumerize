#!/bin/bash

set -o errexit

echo "Checking if old backups should be removed"

if [ -n "${REMOVE_ALL_BUT_N_FULL}" ]; then
  echo "Removing all backups except the latest ${REMOVE_ALL_BUT_N_FULL} full backups"
  remove-all-but-n-full $JOB_ID ${REMOVE_ALL_BUT_N_FULL} --force
  echo "remove-all-but-n-full finished"
fi
if [ -n "${REMOVE_ALL_INC_BUT_N_FULL}" ]; then
  echo "Removing incremental backups from all backup chains except the latest ${REMOVE_ALL_INC_BUT_N_FULL} chains"
  remove-all-inc-of-but-n-full $JOB_ID ${REMOVE_ALL_INC_BUT_N_FULL} --force
  echo "remove-all-inc-of-but-n-full finished"
fi
if [ -n "${REMOVE_OLDER_THAN}" ]; then
  echo "Removing all backups older than ${REMOVE_OLDER_THAN} if they are no more recent ones that depend on them"
  remove-older-than $JOB_ID ${REMOVE_OLDER_THAN} --force
  echo "remove-older-than finished"
fi
