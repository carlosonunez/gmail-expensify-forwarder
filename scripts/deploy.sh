#!/usr/bin/env bash
for command in vendor deploy-infra deploy-functions
do
  >&2 echo "INFO: Running stage '$command'"
  compose_file_to_use=$(grep -Hl "${command}:" docker-compose*yml)
  docker-compose -f $compose_file_to_use run --rm "${command}" || exit 1
done
