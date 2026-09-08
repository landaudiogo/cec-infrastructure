#! bash

set -e

script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

head -c 16 /dev/urandom | od -An -t x | tr -d ' ' > "${decrypted_d}/creds-key"
key=$(cat "${decrypted_d}/creds-key")

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "creds-key"
    },
    "data": {
        "creds-key": "'"$key"'"
    }
}' > "${decrypted_d}/creds-key.json"
