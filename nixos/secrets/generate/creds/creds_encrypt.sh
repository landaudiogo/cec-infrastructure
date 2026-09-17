#! bash

set -euo pipefail

parent_d="$(dirname "$CREDS_DIR")"

pushd "$parent_d"
zip -r "${parent_d}/creds.zip" "./creds" 
popd

openssl enc -aes-256-cbc -pbkdf2 -salt \
  -in "${parent_d}/creds.zip" \
  -out "$CREDS_ENC" \
  -pass "file:$CREDS_KEY"

rm "$parent_d/creds.zip"
