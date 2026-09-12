#! bash
#
# Script to create the administrator credentials
#
# Required environment variables:
#   * ADMIN_CREDS_DIR
#   * CA_CRT
#   * CA_KEY
#   * STORE_PASS

set -euo pipefail

admin_creds_dir="${ADMIN_CREDS_DIR}"


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

make_client_props () {
    cat << EOF > "$2"
security.protocol = SSL
ssl.truststore.location=creds/admins/$1/kafka.truststore.pkcs12
ssl.truststore.password=${STORE_PASS}
ssl.keystore.location=creds/admins/$1/kafka.keystore.pkcs12
ssl.keystore.password=${STORE_PASS}
ssl.endpoint.identification.algorithm=
EOF
}


for i in landau nishant
do
	echo "------------------------------- $i -------------------------------"
    admin_dir=${admin_creds_dir}/${i}

    mkdir -p ${admin_dir}

    make_cnf $i ${admin_dir}/${i}.cnf
    make_client_props $i ${admin_dir}/client-ssl.properties
    cp "${CA_CRT}" ${admin_dir}/

    # Create server key & certificate signing request(.csr file)
    openssl req -new \
    -newkey rsa:2048 \
    -keyout ${admin_dir}/$i.key \
    -out ${admin_dir}/$i.csr \
    -config ${admin_dir}/$i.cnf \
    -nodes

    # Sign server certificate with CA
    openssl x509 -req \
    -days 200 \
    -in ${admin_dir}/$i.csr \
    -CA "${CA_CRT}" \
    -CAkey "${CA_KEY}" \
    -CAcreateserial \
    -out ${admin_dir}/$i.crt \
    -extfile ${admin_dir}/$i.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${admin_dir}/$i.crt \
    -inkey ${admin_dir}/$i.key \
    -chain \
    -CAfile "${CA_KEY}" \
    -name $i \
    -out ${admin_dir}/$i.p12 \
    -password "pass:${STORE_PASS}"

    # Create server keystore
    keytool -importkeystore \
    -deststorepass "${STORE_PASS}" \
    -destkeystore ${admin_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${admin_dir}/$i.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass "${STORE_PASS}"

    keytool -keystore ${admin_dir}/kafka.truststore.pkcs12 \
    -alias CARoot \
    -importcert -file "${CA_CRT}" \
    -noprompt \
    -storepass "${STORE_PASS}" \
    -deststoretype PKCS12

    rm "${admin_dir}/${i}".*
done
