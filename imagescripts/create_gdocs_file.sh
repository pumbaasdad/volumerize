#!/bin/bash

set -o errexit

source /opt/volumerize/env.sh

file_env "GOOGLE_DRIVE_SECRET"

if [ -n "${GOOGLE_DRIVE_ID}" ] && [ -n "${GOOGLE_DRIVE_SECRET}" ]; then
  cat > /credentials/cred.file <<EOF
client_config_backend: settings
client_config:
    client_id: ${GOOGLE_DRIVE_ID}
    client_secret: ${GOOGLE_DRIVE_SECRET}
save_credentials: True
save_credentials_backend: file
save_credentials_file: ${GOOGLE_DRIVE_CREDENTIAL_FILE}
get_refresh_token: True
EOF
fi
