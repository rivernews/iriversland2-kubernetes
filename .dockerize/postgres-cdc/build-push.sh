# dockerhub page https://hub.docker.com/repository/docker/shaungc/postgres-cdc

docker build -f Dockerfile -t shaungc/postgres-cdc:11.5-r24 .
docker push shaungc/postgres-cdc