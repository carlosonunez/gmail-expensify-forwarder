import pulumi, os, json
from pulumi_aws import s3, iam

# TODO: Create SSM user, group and policy docs here.

for required_env_var in ['SERVERLESS_BUCKET_NAME']:
    if os.environ.get(required_env_var) == None:
        raise "Please define " + required_env_var

minimal_serverless_iam_policy_json = json.loads(
    open('files/serverless_iam_policy.json', 'r').read())
serverless_bucket = s3.Bucket('bucket', bucket=os.environ.get('SERVERLESS_BUCKET_NAME'))
serverless_iam_group = iam.Group('gmail-expensify-serverless-group')
serverless_iam_user_policy = iam.GroupPolicy('gmail-expensify-forwarder-serverless-user-policy',
                                             policy=json.dumps(minimal_serverless_iam_policy_json),
                                             group=serverless_iam_group.name)
serverless_iam_user = iam.User('gmail-expensify-forwarder-serverless-user')
_ = iam.GroupMembership('gmail-expensify-forwarder-serverless-group-memberships',
                        group=serverless_iam_group,
                        users=[serverless_iam_user])
