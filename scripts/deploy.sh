#!/usr/bin/env bash

check_if_new_deploy_is_needed() {
  items_that_would_trigger_new_commit=$(cat <<-ITEMS
bin/
lib/
infra/
Dockerfile
Gemfile
serverless.yml
env.gpg
ITEMS
)
  for item in "$items_that_would_trigger_new_commit"
  do
    if grep -q -- "$item" < <(git diff --stat "${GITHUB_SHA:-HEAD}~1")
    then
      >&2 echo "INFO: Since this file or directory was changed, we will re-deploy: $item"
      return 0
    fi
  done
  return 1
}

DOCKER_COMPOSE_BIN=${DOCKER_COMPOSE_LOCATION:-/usr/local/bin}/docker-compose

if ! check_if_new_deploy_is_needed
then
  >&2 echo "INFO: No files or directories that would trigger a new deploy \
have been detected in this commit. Doing nothing."
  exit 0
fi

for command in vendor deploy-infra deploy-functions
do
  >&2 echo "INFO: Running stage '$command'"
  compose_file_to_use=$(grep -Hl "${command}:" docker-compose*yml)
  "${DOCKER_COMPOSE_BIN}" -f $compose_file_to_use run --rm "${command}" || exit 1
done
