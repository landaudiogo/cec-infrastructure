#! bash
#
# Script to create the group credentials
#
# Required environment variables:
#   * CREDS_DIR
#   * CA_CRT
#   * CA_KEY
#   * CA_FILE: CA_CRT CA_KEY merged
#   * STORE_PASS
#   * GRAFANA_SECRET

USAGE="Usage: create_group_creds.sh <number-groups>

Options:
    <number-groups> is a required argument and must be an integer
"


function make_cnf () {
    cat << EOF > "$2"
[req]
prompt = no
distinguished_name = dn
default_md = sha256
default_bits = 4096

[ dn ]
countryName = US
organizationName = CONFLUENT
localityName = MountainView
commonName=$1
EOF
}

make_client_props () {
    cat << EOF > "$2"
security.protocol = SSL
ssl.truststore.location=creds/clients/$1/kafka.truststore.pkcs12
ssl.truststore.password=$STORE_PASS
ssl.keystore.location=creds/clients/$1/kafka.keystore.pkcs12
ssl.keystore.password=$STORE_PASS
EOF
}

if [ $# -eq 0 ]; then
    cat <<< $USAGE
    exit 1;
fi 

if ! [[ $1 =~ [0-9]+ ]]; then 
    cat <<< $USAGE
    exit 1
fi

shopt -s nullglob
set -e
group_creds_dir="$CREDS_DIR/groups"

for (( i=1; i<="$1"; i++ ))
do
    group_name="group${i}"
	echo "------------------------------- $group_name -------------------------------"
    group_dir=${group_creds_dir}/${group_name}

    mkdir -p ${group_dir}

    make_cnf $group_name ${group_dir}/${group_name}.cnf
    make_client_props $group_name ${group_dir}/client-ssl.properties
    cp "$CA_CRT" ${group_dir}/ca.crt


    # Create server key & certificate signing request(.csr file)
    openssl req -new \
    -newkey rsa:2048 \
    -keyout ${group_dir}/$group_name.key \
    -out ${group_dir}/$group_name.csr \
    -config ${group_dir}/$group_name.cnf \
    -nodes

    # Sign server certificate with CA
    openssl x509 -req \
    -days 200 \
    -in ${group_dir}/$group_name.csr \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out ${group_dir}/$group_name.crt \
    -extfile ${group_dir}/$group_name.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${group_dir}/$group_name.crt \
    -inkey ${group_dir}/$group_name.key \
    -chain \
    -CAfile "$CA_FILE" \
    -name $group_name \
    -out ${group_dir}/$group_name.p12 \
    -password "pass:$STORE_PASS"

    # Create server keystore
    keytool -importkeystore \
    -deststorepass "$STORE_PASS" \
    -destkeystore ${group_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${group_dir}/$group_name.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass "$STORE_PASS"

    keytool -keystore ${group_dir}/kafka.truststore.pkcs12 \
    -alias CARoot \
    -importcert -file "$CA_CRT" \
    -noprompt \
    -storepass "$STORE_PASS" \
    -deststoretype PKCS12

    rm "${group_dir}/${group_name}".*

    generate-jwt-token --client-id "$group_name" > "${group_dir}/token"
    grafana_password="$(jq -r '.data.'"$group_name" < "$GRAFANA_SECRET" | base64 -d)"
    echo "USERNAME=${group_name}"$'\n'"PASSWORD=${grafana_password}" > "${group_dir}/grafana"
done
