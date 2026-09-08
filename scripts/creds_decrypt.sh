#! bash

set -eo pipefail

openssl enc -d -aes-256-cbc -pbkdf2 -salt \
  -in "nixos/secrets/creds.zip.enc" \
  -out creds.zip \
  -pass "file:./nixos/secrets/.decrypted/creds-key"
