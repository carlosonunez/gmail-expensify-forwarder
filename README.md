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

## Privacy Notice

This script requires the ability to view and send email on your behalf. It does so by retrieving
and storing credentials locally. These credentials are stored locally and will never be shared without
your consent.

If you run this script on AWS Lambda, it stores these credentials inside of AWS Parameter Store. This
script does not create IAM users on your behalf. Ensure that the IAM user you use for Lambda is only
given enough permissions to read and write to Parameter Store. You can do this by giving it the
"AmazonSSMParameterStoreFullAccess" policy.

## Installing

**NOTE**: You will need Docker and Docker Compose for this to work.

Copy and paste this to install the Forwarder onto your machine.

```sh
curl -Lso https://raw.githubusercontent.com/carlosonunez/gmail-expensify-forwarder/stable/scripts/setup.sh
./setup.sh
```

Answer the questions.


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
