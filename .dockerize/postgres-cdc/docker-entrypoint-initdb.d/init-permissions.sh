#!/bin/bash
# inspired by https://github.com/debezium/docker-images/blob/master/postgres/11/docker-entrypoint-initdb.d/init-permissions.sh

set -e

echo "INFO: ready to copy our custom pg_hba.conf"
echo "INFO: PGDATA check=$PGDATA"
cp /data/pg_hba.conf "$PGDATA/pg_hba.conf"