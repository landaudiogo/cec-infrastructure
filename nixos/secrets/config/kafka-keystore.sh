#! bash

set -e

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

USAGE="
Usage: $script key

Positional parameters:
    key: password with which to encrypt the truststore and keystore
"


if [[ $# -ne "1" ]]; then
    echo "$USAGE"
    exit 1
fi

key="$(printf $1 | base64)"

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
