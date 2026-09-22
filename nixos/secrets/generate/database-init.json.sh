#! bash

set -euo pipefail

SECRET_NAME="database-init"

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"


keys=(
    "init.sql"
    "database-secret.json"
)

for key in "${keys[@]}"; do
    agenix -d "$key.age" > "${decrypted_d}/$key"
done

grafanareader_password="$(jq -r '.data.GRAFANAREADER_PASSWORD' < "${decrypted_d}/database-secret.json" | base64 -d)"
sql="$(sed -e "s/{{GRAFANAREADER_PASSWORD}}/${grafanareader_password}/" < "${decrypted_d}/init.sql" | base64 -w 0)"

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "'"$SECRET_NAME"'"
    },
    "data": {
        "init.sql": "'"$sql"'"
    }
}' > "${decrypted_d}/$SECRET_NAME.json"
