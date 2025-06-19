import boto3
import os

def handler(event, context):
    instance_id = os.environ["INSTANCE_ID"]
    ec2 = boto3.client("ec2")
    try:
        response = ec2.start_instances(InstanceIds=[instance_id])
        return {
            "statusCode": 200,
            "body": f"Starting instance {instance_id}: {response}"
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error starting instance {instance_id}: {e}"
        }
