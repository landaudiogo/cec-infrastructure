#! bash

set -eo pipefail

broker_creds_dir="creds/brokers"


for i in kafka-1 kafka-2 kafka-3
do
	echo "------------------------------- $i -------------------------------"

    broker_dir=${broker_creds_dir}/${i}
    mkdir -p ${broker_dir}


    cp config/${i}.cnf ${broker_dir}

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
    -CA ca/ca.crt \
    -CAkey ca/ca.key \
    -CAcreateserial \
    -out ${broker_dir}/$i.crt \
    -extfile ${broker_dir}/$i.cnf

    # Convert server certificate to pkcs12 format
    openssl pkcs12 -export \
    -in ${broker_dir}/$i.crt \
    -inkey ${broker_dir}/$i.key \
    -chain \
    -CAfile ca/ca.pem \
    -name $i \
    -out ${broker_dir}/$i.p12 \
    -password pass:cc2023

    # Create server keystore
    keytool -importkeystore \
    -deststorepass cc2023 \
    -destkeystore ${broker_dir}/kafka.keystore.pkcs12 \
    -srckeystore ${broker_dir}/$i.p12 \
    -deststoretype PKCS12  \
    -srcstoretype PKCS12 \
    -noprompt \
    -srcstorepass cc2023

    keytool -keystore ${broker_dir}/kafka.truststore.jks \
    -alias CARoot \
    -importcert -file ca/ca.crt -noprompt -storepass cc2023

    # Save creds
    echo "cc2023" > ${broker_dir}/sslkey_creds
    echo "cc2023" > ${broker_dir}/keystore_creds

done


