#!/bin/bash

if [ ${VOLUMERIZE_REPLICATE} == "true" ]; then
  /etc/volumerize/replicate $JOB_ID
fi