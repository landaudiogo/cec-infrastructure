#! bash

set -eo pipefail

zip -r "creds.zip" "creds" 

openssl enc -aes-256-cbc -pbkdf2 -salt \
  -in creds.zip \
  -out "nixos/secrets/creds.zip.enc" \
  -pass "file:./nixos/secrets/.decrypted/creds-key"

rm creds.zip
