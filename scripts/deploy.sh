#!/usr/bin/env bash
DOCKER_COMPOSE_BIN=${DOCKER_COMPOSE_LOCATION:-/usr/local/bin}/docker-compose
for command in vendor deploy-infra deploy-functions
do
  >&2 echo "INFO: Running stage '$command'"
  compose_file_to_use=$(grep -Hl "${command}:" docker-compose*yml)
  "${DOCKER_COMPOSE_BIN}" -f $compose_file_to_use run --rm "${command}" || exit 1
done
