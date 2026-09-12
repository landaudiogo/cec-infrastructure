#! bash
#
# Script to generate the creds.zip.enc file
#

set -euo pipefail

keys=(
    "students.json"
    "groups.json"
    "root-ca-key.pem"
    "root-ca.pem"
    "creds-key"
    "kafka-keystore-key"
)

for key in "${keys[@]}"; do
    agenix -d "$key.age" > ".decrypted/$key"
done

create_admin_creds.sh
create_broker_creds.sh
create_group_creds.sh
create_client_creds.sh
