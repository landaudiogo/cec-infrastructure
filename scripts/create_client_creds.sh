#!/bin/bash 

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
ssl.truststore.password=cc2023
ssl.keystore.location=creds/clients/$1/kafka.keystore.pkcs12
ssl.keystore.password=cc2023
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
client_creds_dir="creds/clients"

for (( i=1; i<="$1"; i++ ))
do
    client_name="client${i}"
	echo "------------------------------- $client_name -------------------------------"
    client_dir=${client_creds_dir}/${client_name}

    mkdir -p ${client_dir}

    make_cnf $client_name ${client_dir}/${client_name}.cnf
    make_client_props $client_name ${client_dir}/client-ssl.properties
    cp ca/ca.crt ${client_dir}/


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
    -CA ca/ca.crt \
    -CAkey ca/ca.key \
    -CAcreateserial \
    -out ${client_dir}/$client_name.crt \
    -extfile ${client_dir}/$client_name.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${client_dir}/$client_name.crt \
    -inkey ${client_dir}/$client_name.key \
    -chain \
    -CAfile ca/ca.pem \
    -name $client_name \
    -out ${client_dir}/$client_name.p12 \
    -password pass:cc2023

    # Create server keystore
    keytool -importkeystore \
    -deststorepass cc2023 \
    -destkeystore ${client_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${client_dir}/$client_name.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass cc2023

    keytool -keystore ${client_dir}/kafka.truststore.pkcs12 \
    -alias CARoot \
    -importcert -file ca/ca.crt \
    -noprompt \
    -storepass cc2023 \
    -deststoretype PKCS12

    rm "${client_dir}/${client_name}".*
done
