#! bash
#
# Script to generate the creds.zip.enc file
# Dependencies:
#   agenix, dirname, openssl, keytool

set -euo pipefail

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

keys=(
    "students.json"
    "groups.json"
    "root-ca-key.pem"
    "root-ca.pem"
    "creds-key"
    "kafka-keystore-key"
    "grafana.json"
)

for key in "${keys[@]}"; do
    agenix -d "$key.age" > "${decrypted_d}/$key"
done

# Create root-ca-file as merge between public and private key
cat "$decrypted_d/root-ca.pem" "$decrypted_d/root-ca-key.pem"  > "$decrypted_d/root-ca-file.pem"

mkdir -p "${decrypted_d}/creds"

export CREDS_DIR="$decrypted_d/creds"
export CREDS_KEY="$decrypted_d/creds-key"
export CREDS_ENC="${script_d}/../creds.zip.enc"
export STUDENT_CREDENTIALS="$decrypted_d/students.json"
export GROUP_CREDENTIALS="$decrypted_d/groups.json"
export CA_CRT="$decrypted_d/root-ca.pem"
export CA_KEY="$decrypted_d/root-ca-key.pem"
export RSA_PRIVATE_KEY="$decrypted_d/root-ca-key.pem"
export CA_FILE="$decrypted_d/root-ca-file.pem"
export STORE_PASS="$(cat "${decrypted_d}/kafka-keystore-key")"
export GRAFANA_SECRET="$decrypted_d/grafana.json"

bash "${script_d}/creds/create_admin_creds.sh"
bash "${script_d}/creds/create_broker_creds.sh"
bash "${script_d}/creds/create_group_creds.sh" 20
bash "${script_d}/creds/create_client_creds.sh" 70
python "${script_d}/creds/parse_creds.py"
bash "${script_d}/creds/zip_client_creds.sh"
bash "${script_d}/creds/zip_group_creds.sh"
bash "${script_d}/creds/creds_encrypt.sh"
