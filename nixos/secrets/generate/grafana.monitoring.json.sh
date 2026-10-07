#! bash

set -euo pipefail

SECRET_NAME="grafana.monitoring"

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

admin_user="$(printf "landau" | base64)"
admin_password="$(head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' | base64)"

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "grafana",
        "namespace": "monitoring" 
    },
    "data": {
        "admin-user": "'"$admin_user"'",
        "admin-password": "'"$admin_password"'"
    }
}' | jq > "${decrypted_d}/$SECRET_NAME.json"
