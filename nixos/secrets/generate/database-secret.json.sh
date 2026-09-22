#! bash

set -e

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

postgres_password="$(head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' | base64)"
grafanareader_password="$(head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' | base64)"
pgadmin_password="$(head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' | base64)"


echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "database"
    },
    "data": {
        "POSTGRES_PASSWORD": "'"$postgres_password"'",
        "GRAFANAREADER_PASSWORD": "'"$grafanareader_password"'",
        "PGADMIN_DEFAULT_PASSWORD": "'"$pgadmin_password"'"
    }
}' > "${decrypted_d}/database-secret.json"
