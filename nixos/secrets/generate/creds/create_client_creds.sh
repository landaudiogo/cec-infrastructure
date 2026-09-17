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

USAGE="Usage: create_client_creds.sh <number-clients>

Options:
    <number-clients> is a required argument and must be an integer
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
client_creds_dir="$CREDS_DIR/clients"

for (( i=1; i<="$1"; i++ ))
do
    client_name="client${i}"
	echo "------------------------------- $client_name -------------------------------"
    client_dir=${client_creds_dir}/${client_name}

    mkdir -p ${client_dir}

    make_cnf $client_name ${client_dir}/${client_name}.cnf
    make_client_props $client_name ${client_dir}/client-ssl.properties
    cp "$CA_CRT" "${client_dir}/ca.crt"


    # Create server key & certificate signing request(.csr file)
    openssl req -new \
    -newkey rsa:2048 \
    -keyout ${client_dir}/$client_name.key \
    -out ${client_dir}/$client_name.csr \
    -config ${client_dir}/$client_name.cnf \
    -nodes

    # Sign server certificate with CA
    openssl x509 -req \
    -days 200 \
    -in ${client_dir}/$client_name.csr \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out ${client_dir}/$client_name.crt \
    -extfile ${client_dir}/$client_name.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${client_dir}/$client_name.crt \
    -inkey ${client_dir}/$client_name.key \
    -chain \
    -CAfile "$CA_FILE" \
    -name $client_name \
    -out ${client_dir}/$client_name.p12 \
    -password "pass:$STORE_PASS"

    # Create server keystore
    keytool -importkeystore \
    -deststorepass "$STORE_PASS" \
    -destkeystore ${client_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${client_dir}/$client_name.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass "$STORE_PASS"

    keytool -keystore ${client_dir}/kafka.truststore.pkcs12 \
    -alias CARoot \
    -importcert -file "$CA_CRT" \
    -noprompt \
    -storepass "$STORE_PASS" \
    -deststoretype PKCS12

    rm "${client_dir}/${client_name}".*
done
