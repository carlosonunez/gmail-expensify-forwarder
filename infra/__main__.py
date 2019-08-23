import pulumi
from pulumi_aws import s3

config = pulumi.Config('gmail-expensify-forwarder')

serverless_bucket = s3.bucket(os.environ['SERVERLESS_BUCKET_NAME'])
