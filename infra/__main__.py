import pulumi, os, json
from pulumi_aws import s3, iam

for required_env_var in ['SERVERLESS_BUCKET_NAME']:
    if os.environ.get(required_env_var) == None:
        raise "Please define " + required_env_var

minimal_serverless_iam_policy_file = open('files/serverless_iam_policy.json')
minimal_serverless_iam_policy = minimal_serverless_iam_policy_file.read()

config = pulumi.Config('gmail-expensify-forwarder')
serverless_bucket = s3.Bucket(os.environ.get('SERVERLESS_BUCKET_NAME'))
serverless_iam_user = iam.User('gmail-expensify-forwarder-serverless-user')
serverless_iam_user_policy = iam.UserPolicy('gmail-expensify-forwarder-serverless-user-policy',
                                            policy=minimal_serverless_iam_policy,
                                            user=serverless_iam_user.name)
