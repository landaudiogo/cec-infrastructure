#! bash

set -euo pipefail

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
secrets_d="$script_d/../nixos/secrets"
decrypted_d="${secrets_d}/.decrypted"

pushd "$secrets_d"

keys=(
    "creds-key"
)

for key in "${keys[@]}"; do
    agenix -d "$key.age" > "${decrypted_d}/$key"
done

openssl enc -d -aes-256-cbc -pbkdf2 -salt \
  -in "${secrets_d}/creds.zip.enc" \
  -out "${decrypted_d}/creds.zip" \
  -pass "file:${decrypted_d}/creds-key"

unzip "$decrypted_d/creds.zip" -d "$decrypted_d/"
