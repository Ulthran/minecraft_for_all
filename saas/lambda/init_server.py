import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codebuild = boto3.client("codebuild")
PROJECT_NAME = os.environ.get("PROJECT_NAME", "minecraft-tenant-terraform")


def handler(event, context):
    logger.debug("Event received: %s", event)
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid json"})}

    tenant_id = body.get("tenant_id")
    if not tenant_id:
        return {"statusCode": 400, "body": json.dumps({"error": "tenant_id required"})}

    params = [
        {"name": "TENANT_ID", "value": tenant_id, "type": "PLAINTEXT"},
        {"name": "SERVER_TYPE", "value": body.get("server_type", "papermc"), "type": "PLAINTEXT"},
        {"name": "INSTANCE_TYPE", "value": body.get("instance_type", "t4g.medium"), "type": "PLAINTEXT"},
        {"name": "OVERWORLD_BORDER", "value": str(body.get("overworld_border", 3000)), "type": "PLAINTEXT"},
        {"name": "NETHER_BORDER", "value": str(body.get("nether_border", 3000)), "type": "PLAINTEXT"},
    ]

    try:
        codebuild.start_build(projectName=PROJECT_NAME, environmentVariablesOverride=params)
    except Exception as e:
        logger.exception("Failed to start build")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    return {"statusCode": 200, "body": json.dumps({"status": "started"})}
