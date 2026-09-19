#! bash

set -euo pipefail

script=$(basename "$0")
script_d="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
decrypted_d="${script_d}/../.decrypted"

head -c 16 /dev/urandom | od -An -t x | tr -d '[:space:]' > "${decrypted_d}/event-secret"
