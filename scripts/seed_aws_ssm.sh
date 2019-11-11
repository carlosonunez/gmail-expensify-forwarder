#!/usr/bin/env sh
EMAIL_ADDRESS_TO_SEED_WITH="${EMAIL_ADDRESS_TO_SEED_WITH?Please provide an email address to seed.}"
email_address_hashed=$(printf "$EMAIL_ADDRESS_TO_SEED_WITH" | md5sum | awk '{print $1}')
AWS_SSM_NAMESPACE="/gmail-expensify-forwarder/$email_address_hashed"

if ! test -f /.dockerenv
then
  >&2 echo "ERROR: This script is meant to be run from within Docker. \
Use the 'seed-aws-ssm' Docker Compose service to run this script."
  exit 1
fi
for file in "$CREDENTIALS_PATH" "$TOKEN_PATH"
do
  if ! test -f "$file"
  then
    >&2 echo "ERROR: Ensure that $file is present."
    exit 1
  fi
done

seed_gmail_credentials() {
  aws ssm put-parameter --name "${AWS_SSM_NAMESPACE}/credentials" \
    --description "Gmail credentials to use" \
    --value "$(cat "$CREDENTIALS_PATH")" \
    --type "String" \
    --overwrite \
    --tier 'Standard'
}

seed_gmail_tokens() {
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

seed_email_sender() {
  aws ssm put-parameter --name "${AWS_SSM_NAMESPACE}/email_sender" \
    --value "$EMAIL_SENDER" \
    --overwrite \
    --type "String" \
    --tier 'Standard'
}

seed_last_run_time && \
  seed_email_sender && \
  seed_gmail_application_name && \
  seed_gmail_credentials && \
  seed_gmail_tokens
