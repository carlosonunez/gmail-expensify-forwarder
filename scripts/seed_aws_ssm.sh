#!/usr/bin/env sh
AWS_SSM_NAMESPACE='/gmail-expensify-forwarder'

if ! test -f /.dockerenv
then
  >&2 echo "ERROR: This script is meant to be run from within Docker. \
Use the 'seed-aws-ssm' Docker Compose service to run this script."
  exit 1
fi

seed_gmail_credentials() {
  if ! test -f "$CREDENTIALS_PATH"
  then
    >&2 echo "ERROR: Couldn't find Gmail credentials; store them here: $CREDENTIALS_PATH"
    exit 1
  fi

  aws ssm put-parameter --name "${AWS_SSM_NAMESPACE}/credentials" \
    --description "Gmail credentials to use" \
    --value "$(cat "$CREDENTIALS_PATH")" \
    --type "String" \
    --overwrite \
    --tier 'Standard'
}

seed_gmail_tokens() {
  if ! test -f "$TOKEN_PATH"
  then
    >&2 echo "ERROR: Couldn't find Gmail tokens; run forwarder locally, then store \
the tokens here: $TOKEN_PATH"
    exit 1
  fi

  aws ssm put-parameter --name "${AWS_SSM_NAMESPACE}/tokens" \
    --description "Authenticated Gmail tokens to use" \
    --value "$(cat "$TOKEN_PATH")" \
    --overwrite \
    --type "String" \
    --tier 'Standard'
}

seed_last_run_time() {
  aws ssm put-parameter --name "${AWS_SSM_NAMESPACE}/forwarder_last_finished_time_secs" \
    --value "$(date +%s)" \
    --overwrite \
    --type "String" \
    --tier 'Standard'
}

seed_gmail_application_name() {
  aws ssm put-parameter --name "${AWS_SSM_NAMESPACE}/gmail_application_name" \
    --value "$GMAIL_APPLICATION_NAME" \
    --overwrite \
    --type "String" \
    --tier 'Standard'
}

seed_last_run_time && \
  seed_gmail_application_name && \
  seed_gmail_credentials && \
  seed_gmail_tokens
