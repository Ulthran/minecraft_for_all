import boto3
import os
import logging


logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    instance_id = os.environ["INSTANCE_ID"]
    ec2 = boto3.client("ec2")
    logger.info("Starting instance %s", instance_id)
    logger.debug("Event received: %s", event)
    try:
        response = ec2.start_instances(InstanceIds=[instance_id])
        logger.info("Start response: %s", response)
        return {
            "statusCode": 200,
            "body": f"Starting instance {instance_id}: {response}"
        }
    except Exception as e:
        logger.exception("Error starting instance %s", instance_id)
        return {
            "statusCode": 500,
            "body": f"Error starting instance {instance_id}: {e}"
        }
