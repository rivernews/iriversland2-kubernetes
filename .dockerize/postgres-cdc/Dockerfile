FROM postgres:11.5


# This docker image configures postgres for cdc: https://debezium.io/documentation/reference/0.10/postgres-plugins.html#postgresql-server-configuration
# To verify cdc is working, please refer to the two articles below:
# https://www.highgo.ca/2019/08/22/an-overview-of-logical-replication-in-postgresql/
# https://debezium.io/documentation/reference/0.10/postgres-plugins.html#database-test-environment-setup

# add (merge) additional scripts to initdb directory
# https://stackoverflow.com/a/56941391/9814131
COPY ./docker-entrypoint-initdb.d/. /docker-entrypoint-initdb.d/

RUN mkdir /data
COPY pg_hba.conf /data/pg_hba.conf

COPY postgresql.conf.sample /usr/share/postgresql/postgresql.conf.sample
