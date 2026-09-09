#! bash
#
# Script to create all kafka topics.
#
# This script depends on the following nix packages:
#
#   * confluent-platform: kafka-topics.sh; kafka-acls.sh
#   * ...: mktemp
#
# Environment:
#   Required:
#     * BOOTSTRAP_SERVER: Kafka bootstrap server to connect to (e.g. kafka.cec.dlandau.nl:19092) 
#     * KEYSTORE_LOCATION
#     * KEYSTORE_PASSWORD
#     * TRUSTSTORE_LOCATION
#     * TRUSTSTORE_PASSWORD
#
#   Has defaults: 
#     * NCLIENTS: Number of client topics to create (defaults to 60)
#     * NGROUPS: Number of group topics to create (defaults to 20)

set -euo pipefail

create_topic_dev () {
    # This function creates a topic that can only be read 
    # and written to by users with the same name. E.g. If 
    # the topic is named "client1" it can only be read by
    # a user identifying themselves as "client1"

    kafka-topics.sh \
        --command-config "$properties_file" \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --create \
        --topic "$1" \
        --partitions 16 \
        --replication-factor 2

    # # Add write permissions to client
    kafka-acls.sh \
        --command-config "$properties_file" \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --add --allow-principal "User:$1" \
        --operation write \
        --topic "$1"

    # # Add read permissions for topic
    kafka-acls.sh \
        --command-config "$properties_file" \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --add \
        --allow-principal "User:$1" \
        --operation read \
        --topic "$1"

    # # Add read permissions for all groups
    kafka-acls.sh \
        --command-config "$properties_file" \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --add \
        --allow-principal "User:$1" \
        --operation read \
        --group '*'
}

create_topic_demo () {
    kafka-topics.sh \
        --command-config "$properties_file" \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --create \
        --topic "experiment" \
        --partitions 16 \
        --replication-factor 2
}

grant_read_topic_demo () {
    kafka-acls.sh \
        --command-config "$properties_file" \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --add \
        --allow-principal "User:$1" \
        --operation read \
        --topic "experiment"

}


NCLIENTS="${NCLIENTS:-60}"
NGROUPS="${NGROUPS:-20}"

# Create client properties file
properties_file="$(mktemp "./client-ssl.properties.XXXXX")"
echo "
security.protocol=SSL
ssl.truststore.location=${TRUSTSTORE_LOCATION}
ssl.truststore.password=${TRUSTSTORE_PASSWORD}
ssl.keystore.location=${KEYSTORE_LOCATION}
ssl.keystore.password=${KEYSTORE_PASSWORD}
ssl.endpoint.identification.algorithm=
" > "$properties_file"

for (( i=1; i<="$NCLIENTS"; i++ )); do
    user="client${i}"
    echo "create topic: ${user}"
    create_topic_dev "$user"
done

create_topic_demo
for (( i=1; i<="$NGROUPS"; i++ )); do
    user="group${i}"
    echo "create topic: ${user}"
    create_topic_dev "$user"
    grant_read_topic_demo "$user"
done
