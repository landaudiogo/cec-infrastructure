#!/bin/bash 

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
group_creds_dir="creds/groups"

for (( i=1; i<="$1"; i++ ))
do
    group_name="group${i}"
	echo "------------------------------- $group_name -------------------------------"
    group_dir=${group_creds_dir}/${group_name}

    mkdir -p ${group_dir}

    make_cnf $group_name ${group_dir}/${group_name}.cnf
    make_client_props $group_name ${group_dir}/client-ssl.properties
    cp ca/ca.crt ${group_dir}/


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
    -CA ca/ca.crt \
    -CAkey ca/ca.key \
    -CAcreateserial \
    -out ${group_dir}/$group_name.crt \
    -extfile ${group_dir}/$group_name.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${group_dir}/$group_name.crt \
    -inkey ${group_dir}/$group_name.key \
    -chain \
    -CAfile ca/ca.pem \
    -name $group_name \
    -out ${group_dir}/$group_name.p12 \
    -password pass:cc2023

    # Create server keystore
    keytool -importkeystore \
    -deststorepass cc2023 \
    -destkeystore ${group_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${group_dir}/$group_name.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass cc2023

    keytool -keystore ${group_dir}/kafka.truststore.pkcs12 \
    -alias CARoot \
    -importcert -file ca/ca.crt \
    -noprompt \
    -storepass cc2023 \
    -deststoretype PKCS12

    rm "${group_dir}/${group_name}".*
done
