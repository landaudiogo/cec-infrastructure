#! bash
#
# Script to create the broker credentials
#
# Required environment variables:
#   * CREDS_DIR
#   * CA_CRT
#   * CA_KEY
#   * CA_FILE: CA_CRT CA_KEY merged
#   * STORE_PASS

set -euo pipefail

broker_creds_dir="$CREDS_DIR/brokers"

make_cnf () {
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


for i in kafka-1 kafka-2 kafka-3
do
	echo "------------------------------- $i -------------------------------"

    broker_dir="${broker_creds_dir}/${i}"
    mkdir -p "${broker_dir}"


    make_cnf "$i" "${broker_dir}/${i}.cnf"

    # Create server key & certificate signing request(.csr file)
    openssl req -new \
    -newkey rsa:2048 \
    -keyout ${broker_dir}/$i.key \
    -out ${broker_dir}/$i.csr \
    -config ${broker_dir}/$i.cnf \
    -nodes


    # Sign server certificate with CA
    openssl x509 -req \
    -days 200 \
    -in ${broker_dir}/$i.csr \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out ${broker_dir}/$i.crt \
    -extfile ${broker_dir}/$i.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${broker_dir}/$i.crt \
    -inkey ${broker_dir}/$i.key \
    -chain \
    -CAfile "$CA_FILE" \
    -name $i \
    -out ${broker_dir}/$i.p12 \
    -password "pass:${STORE_PASS}"

    # Create server keystore
    keytool -importkeystore \
    -deststorepass "$STORE_PASS" \
    -destkeystore "${broker_dir}/kafka.keystore.pkcs12" \
    -srckeystore "${broker_dir}/$i.p12" \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass "$STORE_PASS"

    keytool -keystore "${broker_dir}/kafka.truststore.jks" \
    -alias CARoot \
    -importcert -file "$CA_CRT" -noprompt -storepass "$STORE_PASS"

    # Save creds
    echo "$STORE_PASS" > "${broker_dir}/sslkey_creds"
    echo "$STORE_PASS" > "${broker_dir}/keystore_creds"

done


