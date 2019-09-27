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
CREDENTIALS_FILE_PATH="${CREDENTIALS_FILE_PATH:-${GEF_INSTALL_DIRECTORY}/credentials.json}"

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

_enter_gef_dir() {
  pushd "${GEF_INSTALL_DIRECTORY}" &>/dev/null
}

_exit_gef_dir() {
  popd "${GEF_INSTALL_DIRECTORY}" &>/dev/null
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
  if test -d "$GEF_INSTALL_DIRECTORY"
  then
    log_warn "Forwarder already installed. Continuing."
    return 0
  fi
  mkdir -p "$GEF_INSTALL_DIRECTORY"
  git clone --branch stable "${GEF_GITHUB_URL}" "$GEF_INSTALL_DIRECTORY"
}

# Asks the user to supply the credentials file, unless it has already been supplied
# in CREDENTIALS_FILE_PATH.
prompt_for_gmail_credentials_json() {
  log_info "Checking for Gmail credentials"
  if ! test -f "$CREDENTIALS_FILE_PATH"
  then
    cat <<-GMAIL_CREDENTIALS_PROMPT
Welcome to the Gmail Expensify Forwarder! I hope this script saves you as much
time as it's saved me.

To begin, you'll need to provide the script with credentials to Gmail. This is
used to create a token that the Forwarder uses to search your inbox and forward
receipts.

This file is saved locally and isn't sent to anyone.

Here's what you'll do:

1. Open this link in your browser: ${RUBY_QUICKSTART_LINK}
2. Click "Enable the Gmail API." Sign in if prompted.
3. Click "Download Client Configuration". Save it as the file below:
   ${CREDENTIALS_FILE_PATH}

The script will automatically continue once you've downloaded this file.
GMAIL_CREDENTIALS_PROMPT
  while true
  do
    test -f "$CREDENTIALS_FILE_PATH" && break
    sleep 1
  done
  fi
}

# Creates the environment file, which Compose needs even though we won't
# be using it (unless we deploy to AWS)
create_environment_file() {
  log_info "Creating environment file"
  _enter_gef_dir
  scripts/create_env.sh
  _exit_gef_dir
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
