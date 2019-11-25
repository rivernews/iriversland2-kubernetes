# set prefix for postgres connector for each database
# NOTICE: postgres slot name can only contain [a-z0-9_]: https://github.com/zalando/patroni/pull/277
DATABASE_APPLTRACKY_LOGICAL_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME:-appl_tracky}

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
echo "INFO: launching kafka connect in standalone mode..."

${KAFKA_HOME}/bin/connect-standalone.sh ${KAFKA_CONFIG}/kafka-connect.properties ${KAFKA_CONFIG}/postgres-connector.properties ${KAFKA_CONFIG}/elasticsearch-connector.properties
