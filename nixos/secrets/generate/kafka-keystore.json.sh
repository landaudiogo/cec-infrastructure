#! bash

set -e

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

agenix -d kafka-keystore-key.age > "${decrypted_d}/kafka-keystore-key"

key="$(base64 < "${decrypted_d}/kafka-keystore-key")"

echo '{
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "kafka-keystore"
    },
    "data": {
        "KEYSTORE_PASSWORD": "'"$key"'"
    }
}' > "${decrypted_d}/kafka-keystore.json"
