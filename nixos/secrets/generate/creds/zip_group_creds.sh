#! bash

set -euo pipefail

creds_d="$CREDS_DIR/groups"

cd "$creds_d"

while read -r file; do
    zip -r "${file}.zip" "${file}"
done < <(find . -maxdepth 1 -mindepth 1 -type d)
