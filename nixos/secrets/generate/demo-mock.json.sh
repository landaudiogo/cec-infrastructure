#! bash

set -euo pipefail

SECRET_NAME="demo-mock"

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"


keys=(
    "database-secret.json"
    "http-group-id"
    "event-secret"
)

for key in "${keys[@]}"; do
    agenix -d "$key.age" > "${decrypted_d}/$key"
done

key="$(base64 -w 0 < "${decrypted_d}/event-secret")"
postgres_password="$(jq -r '.data.POSTGRES_PASSWORD' < "${decrypted_d}/database-secret.json"  | base64 -d)"
database_url="$(printf "postgres://cec:$postgres_password@postgres:5432/cec" | base64 -w 0)"
group_id="$(base64 -w 0 < "${decrypted_d}/http-group-id")"
min_batch_size="$(printf "$1" | base64 -w 0)"
max_batch_size="$(printf "$2" | base64 -w 0)"

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "'"$SECRET_NAME"'"
    },
    "data": {
        "SECRET_KEY": "'"$key"'",
        "DATABASE_URL": "'"$database_url"'",
        "GROUP_ID": "'"$group_id"'",
        "MIN_BATCH_SIZE": "'"$min_batch_size"'",
        "MAX_BATCH_SIZE": "'"$max_batch_size"'"
    }
}' > "${decrypted_d}/$SECRET_NAME.json"
