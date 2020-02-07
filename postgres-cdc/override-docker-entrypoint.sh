#!/usr/bin/env bash

set -e

echo "INFO: Override entrypoint script started. Initially provided environment variables:"
env

export SQL_DATA_VOLUME_MOUNT=${SQL_DATA_VOLUME_MOUNT:-/postgres_cluster_data}

# setup env var so the official docker entrypoint script
# can create all the initial db resources for us
export PGPASSWORD=$SQL_PASSWORD # for psql, which our create_database script uses
export POSTGRES_PASSWORD=$SQL_PASSWORD # for `postgres` and official entrypoint to create initial db resoures
export POSTGRES_USER=$SQL_USER
export POSTGRES_DB=$SQL_DATABASE
export PGDATA=$SQL_DATA_VOLUME_MOUNT/pgdata


mkdir -p $SQL_DATA_VOLUME_MOUNT
cp /tmp/pg_hba.conf $SQL_DATA_VOLUME_MOUNT/pg_hba.conf


echo "\n\nINFO: Printing all environment variables after assignment"
env


# postgres official docker container
# https://github.com/docker-library/postgres
echo "INFO: About to run official postgres image entrypoint script"
. /usr/local/bin/docker-entrypoint.sh