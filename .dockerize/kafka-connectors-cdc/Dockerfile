FROM bitnami/kafka:2.3.1-debian-9-r0

# dockerhub: https://hub.docker.com/r/bitnami/kafka
# version follows k8's helm chart: https://github.com/bitnami/charts/blob/master/bitnami/kafka/values.yaml

# default ENV values: https://vsupalov.com/docker-arg-env-variable-guide/#setting-env-values
ENV BOOTSTRAP_SERVERS=kafka-stack-release-0.kafka-stack-release-headless.kube-system.svc.cluster.local:9092
ENV GROUP_ID=1
ENV CONFIG_STORAGE_TOPIC=kafka_connect_configs
ENV OFFSET_STORAGE_TOPIC=kafka_connect_offsets
ENV STATUS_STORAGE_TOPIC=my_connect_statuses

ENV KAFKA_HEAP_OPTS='-Xmx256m -Xms256m'
ENV ALLOW_PLAINTEXT_LISTENER=yes



# using confluent cli: https://docs.confluent.io/current/connect/managing/extending.html#create-a-docker-image-containing-c-hub-connectors
# debezium postgres connector: https://www.confluent.io/hub/debezium/debezium-connector-postgresql
# elasticsearch connector: https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch

# RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:0.10.0 \
#     && confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:5.3.1

RUN mkdir -p /opt/connectors
COPY debezium-connector-postgres /opt/connectors/

# es connector jar hub page: https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch
COPY confluentinc-kafka-connect-elasticsearch-5.3.1 /opt/connectors/




# we replace the default connect-standalone.properties so we can properly resolve to our local Kafka docker development
RUN mkdir -p /opt/kafka/config/
COPY kafka-connect.properties /opt/kafka/config/

# configure connectors: https://docs.confluent.io/current/connect/managing/configuring.html#configuring-connectors
COPY postgres-connector.properties /opt/kafka/config/
COPY elasticsearch-connector.properties /opt/kafka/config/

# standalone mode args: https://docs.confluent.io/5.1.2/connect/userguide.html#standalone-mode
ENTRYPOINT ["/opt/kafka/bin/connect-standalone.sh", "/opt/kafka/config/kafka-connect.properties", "/opt/kafka/config/postgres-connector.properties", "/opt/kafka/config/elasticsearch-connector.properties"]