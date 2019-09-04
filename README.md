# gmail-expensify-forwarder

Forwards emails from Gmail to Expensify.

# Why?

1. All forwarding addresses within Gmail need to be verified.
2. Expensify doesn't know how to forward verification codes to individual accounts.
3. Consequently, you can't add `receipts@expensify.com` as a verified forwarding address.
4. Every other email provider that I've tried to use to get around this either:
  1. Blocks me as spam (looking at you, Outlook), or
  2. Refuses to forward the email due to technical limitations.
5. IFTTT's Gmail integration can't send messages based on labels anymore due to API
  limitations.
6. Zapier works, but I don't want to pay them $20/month for this service.

# How to run

## Before You Start

1. Ensure that you've created a "credentials.json" file as directed by the
[Gmail Quickstart Guide for Ruby](https://developers.google.com/gmail/api/quickstart/ruby).

  Put it somewhere outside of this repository!

2. Copy the example `.env` file: `cp .env.example .env`
3. Change all of the "change me" values that you need to change.

## Locally

Use `docker-compose run --rm forwarder` to run the Forwarder.

## AWS

You can run the Forwarder within AWS Lambda.

1. Run the Forwarder locally _at least once_ to generate `credentials.json` and
   `token.yml` files.

2. Run `scripts/seed_aws_ssm.sh` to populate AWS SSM with the content from the files
   above.

3. Run `scripts/deploy.sh` to deploy underlying infrastructure. Ensure that the
   `PULUMI_ACCESS_TOKEN` and AWS access and secret keys are set per the `.env` file

4. Run `scripts/monitor.sh` to check that your instance of Forwarder is running.

5. Run `scripts/destroy.sh` to stop and remove all instances of Forwarder from Lambda.
