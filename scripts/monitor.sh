#!/usr/bin/env bash
command=monitor-functions
compose_file_to_use=$(grep -Hl "${command}:" docker-compose*yml)
docker-compose -f $compose_file_to_use run --rm "${command}" || exit 1
