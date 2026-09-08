set -eo pipefail

admin_creds_dir="creds/admins"


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
ssl.truststore.password=cc2023
ssl.keystore.location=creds/admins/$1/kafka.keystore.pkcs12
ssl.keystore.password=cc2023
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
    cp ca/ca.crt ${admin_dir}/

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
    -CA ca/ca.crt \
    -CAkey ca/ca.key \
    -CAcreateserial \
    -out ${admin_dir}/$i.crt \
    -extfile ${admin_dir}/$i.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${admin_dir}/$i.crt \
    -inkey ${admin_dir}/$i.key \
    -chain \
    -CAfile ca/ca.pem \
    -name $i \
    -out ${admin_dir}/$i.p12 \
    -password pass:cc2023

    # Create server keystore
    keytool -importkeystore \
    -deststorepass cc2023 \
    -destkeystore ${admin_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${admin_dir}/$i.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass cc2023

    keytool -keystore ${admin_dir}/kafka.truststore.pkcs12 \
    -alias CARoot \
    -importcert -file ca/ca.crt \
    -noprompt \
    -storepass cc2023 \
    -deststoretype PKCS12

    rm "${admin_dir}/${i}".*
done
