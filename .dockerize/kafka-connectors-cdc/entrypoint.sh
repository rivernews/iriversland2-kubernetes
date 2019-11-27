# set prefix for postgres connector for each database
# NOTICE: postgres slot name can only contain [a-z0-9_]: https://github.com/zalando/patroni/pull/277
DATABASE_APPLTRACKY_LOGICAL_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME:-appl_tracky}


wait_till_connected() {
    URL=${1:-localhost}
    MAX_ATTEMPTS=${2:-999}
    RETRY_INTERVAL=${3:-5}

    ATTEMPTS=0
    # use /dev/null to mute output: https://unix.stackexchange.com/a/119650
    until $(curl $URL > /dev/null 2>&1) || [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; do
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "WARNING: Cannot connect to ${URL}, retrying in ${RETRY_INTERVAL} seconds...(${ATTEMPTS}/${MAX_ATTEMPTS})"
        sleep ${RETRY_INTERVAL}
    done

    echo "INFO: Connected to ${URL} sunccessfully."
}


echo ""
echo ""
echo ""
echo "INFO: elasticsearch host is ${ELASTICSEARCH_HOST}"
echo "INFO: elasticsearch port is ${ELASTICSEARCH_PORT}"
echo "INFO: waiting for elasticsearch to be ready..."
wait_till_connected ${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}


echo ""
echo ""
echo ""
echo "INFO: postgres host is ${SQL_HOST}"
echo "INFO: postgres port is ${SQL_PORT}"
echo "INFO: waiting for postgres to be ready..."
wait_till_connected ${SQL_HOST}:${SQL_PORT}


echo ""
echo ""
echo ""
echo "INFO: writing credentials to file..."

echo "POSTGRES_HOST=${SQL_HOST}" > /tmp/credentials.properties
echo "POSTGRES_DATABASE=${SQL_DATABASE}" >> /tmp/credentials.properties
echo "POSTGRES_USER=${SQL_USER}" >> /tmp/credentials.properties
echo "POSTGRES_PASSWORD=${SQL_PASSWORD}" >> /tmp/credentials.properties
echo "POSTGRES_PORT=${SQL_PORT}" >> /tmp/credentials.properties

echo "INFO: writing more properties to file..."
echo "PLUGINS_PATH=${KAFKA_CFG_PLUGIN_PATH}" >> /tmp/credentials.properties

echo "INFO: writing additional postgres properties to file..."
echo "POSTGRES_APPLTRACKY_SERVER_LOGICAL_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME}__postgres" >> /tmp/credentials.properties
echo "POSTGRES_APPLTRACKY_SLOT_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME}__slot" >> /tmp/credentials.properties
echo "POSTGRES_APPLTRACKY_PUBLICATION_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME}__publication" >> /tmp/credentials.properties


echo ""
echo ""
echo ""
echo "INFO: configuring elasticsearch indices..."
# elasticsearch put index API: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
# use HERE document with curl, based on SO: https://stackoverflow.com/questions/34847981/curl-with-multiline-of-json
curl -v -XPUT -H 'Content-Type: application/json' http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_template/template_disable_replicas --data-binary @- << EOF 
{
    "index_patterns": ["*"], 
    "settings": { 
        "index" : {
            "number_of_replicas" : 0
        }
    }
}
EOF

echo ""
echo ""
echo ""
echo "INFO: launching kafka connect in standalone mode..."

${KAFKA_HOME}/bin/connect-standalone.sh ${KAFKA_CONFIG}/kafka-connect.properties ${KAFKA_CONFIG}/postgres-connector.properties ${KAFKA_CONFIG}/elasticsearch-connector.properties
