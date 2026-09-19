#! bash

set -euo pipefail

SECRET_NAME="grafana"

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

grafana_credentials() {
    username="group$1"
    password="$(head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' | base64)"
    echo '"'"$username"'": "'"$password"'",'
}

admin_user="$(printf "landau" | base64)"
admin_password="$(head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' | base64)"
groups="$(for i in $(seq 0 20); do grafana_credentials $i; done)"

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "'"$SECRET_NAME"'"
    },
    "data": {
        '"$groups"'
        "admin-user": "'"$admin_user"'",
        "admin-password": "'"$admin_password"'"
    }
}' | jq > "${decrypted_d}/$SECRET_NAME.json"
