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
  deploy_keyword_to_look_for="__deploy__"
  nondeploy_keyword_to_look_for="__nodeploy__"
  for item in $items_that_would_trigger_new_commit
  do
    if grep -q -- "$item" < <(git diff --stat "${GITHUB_SHA:-HEAD}")
    then
      >&2 echo "INFO: Since this file or directory was changed, we will re-deploy: $item"
      return 0
    elif grep -q -- "$nondeploy_keyword_to_look_for" < <(git log -1 --pretty="%s")
    then
      >&2 echo "INFO: This commit was flagged for non-deployment."
      return 1
    elif grep -q -- "$deploy_keyword_to_look_for" < <(git log -1 --pretty="%s")
    then
      >&2 echo "INFO: A force-deployment has been triggered."
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
