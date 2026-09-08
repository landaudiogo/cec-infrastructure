#! bash

set -e

script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

ADMIN_UUID="$(uuidgen | base64)"
JWT_SECRET="$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ' | base64)"

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "creds-backend"
    },
    "data": {
        "ADMIN_UUID": "'"$ADMIN_UUID"'",
        "JWT_SECRET": "'"$JWT_SECRET"'"
    }
}' > "${decrypted_d}/creds-backend.json"
