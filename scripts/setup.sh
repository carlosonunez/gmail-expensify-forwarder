#!/usr/bin/env bash
# Sets up an instance of the Gmail Expensify Forwarder for your account.
AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
APP_AWS_ACCESS_KEY_ID="$APP_AWS_ACCESS_KEY_ID"
APP_AWS_SECRET_ACCESS_KEY="$APP_AWS_SECRET_ACCESS_KEY"
SERVERLESS_BUCKET_NAME="$SERVERLESS_BUCKET_NAME"
PULUMI_ACCESS_TOKEN="$PULUMI_ACCESS_TOKEN"
EMAIL_SENDER="$EMAIL_SENDER"
GEF_GITHUB_URL="${GEF_GITHUB_URL:-https://github.com/carlosonunez/gmail-expensify-forwarder}"
GEF_INSTALL_DIRECTORY="${HOME}/bin/gmail-expensify-forwarder"

_log() {
  level="${1?Please specify a log level.}"
  message="$2"

  level_downcase="$(echo "$level" | tr '[:upper:]' '[:lower:]')"
  level_upcase="$(echo "$level" | tr '[:lower:]' '[:upper:]')"
  case "$level_downcase" in
    info)
      color='\033[1;32m'
      ;;
    error)
      color='\033[1;31m'
      ;;
    warn)
      color='\033[1;35m'
      ;;
    *)
      >&2 echo "ERROR: Invalid log level --- $level"
      return 1
      ;;
  esac
  reset_colors='\033[m'
  printf "${color}${level_upcase}:${reset_colors} ${message}\n"
}

log_info() {
  _log "info" "$*"
}

log_warn() {
  _log "warn" "$*"
}

log_error() {
  _log "error" "$*"
}

# Clones gmail-expensify-forwarder at stable version.
# TODO: Add support for cloning at HEAD and commit SHAs.
clone_stable_version_of_gmail_expensify_forwarder() {
  log_info "Cloning Gmail Expensify Forwarder"
  mkdir -p "$GEF_INSTALL_DIRECTORY"
  git clone --branch stable "${GEF_GITHUB_URL}" "$GEF_INSTALL_DIRECTORY"
}

if {
  clone_stable_version_of_gmail_expensify_forwarder && \
  create_environment_file && \
  prompt_for_gmail_credentials_json && \
  create_gmail_token_file;
}
then
  >&2 echo "ERROR: Something happened while setting up the Forwarder. \
Check the logs above for more information."
  exit 1
fi

if deploy_to_aws
then
  set_serverless_aws_credentials && \
  set_forwarder_aws_credentials && \
  set_pulumi_token && \
  deploy
fi
