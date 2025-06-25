import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codebuild = boto3.client("codebuild")
PROJECT_NAME = os.environ.get("PROJECT_NAME", "minecraft-tenant-terraform")

ALLOWED_SERVER_TYPES = {"vanilla", "papermc"}
ALLOWED_INSTANCE_TYPES = {"t4g.small", "t4g.medium", "t4g.large"}
MIN_BORDER = 100
MAX_BORDER = 10000


def handler(event, context):
    logger.debug("Event received: %s", event)

    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    tenant_id = claims.get("custom:tenant_id")
    if not tenant_id:
        return {"statusCode": 400, "body": json.dumps({"error": "missing tenant_id"})}

    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid json"})}

    server_type = body.get("server_type", "papermc")
    if server_type not in ALLOWED_SERVER_TYPES:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid server_type"})}

    instance_type = body.get("instance_type", "t4g.medium")
    if instance_type not in ALLOWED_INSTANCE_TYPES:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid instance_type"})}

    try:
        overworld_border = int(body.get("overworld_border", 3000))
    except (TypeError, ValueError):
        return {"statusCode": 400, "body": json.dumps({"error": "invalid overworld_border"})}
    if not MIN_BORDER <= overworld_border <= MAX_BORDER:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid overworld_border"})}

    try:
        nether_border = int(body.get("nether_border", 3000))
    except (TypeError, ValueError):
        return {"statusCode": 400, "body": json.dumps({"error": "invalid nether_border"})}
    if not MIN_BORDER <= nether_border <= MAX_BORDER:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid nether_border"})}

    params = [
        {"name": "TENANT_ID", "value": tenant_id, "type": "PLAINTEXT"},
        {"name": "SERVER_TYPE", "value": server_type, "type": "PLAINTEXT"},
        {"name": "INSTANCE_TYPE", "value": instance_type, "type": "PLAINTEXT"},
        {"name": "OVERWORLD_BORDER", "value": str(overworld_border), "type": "PLAINTEXT"},
        {"name": "NETHER_BORDER", "value": str(nether_border), "type": "PLAINTEXT"},
    ]

    try:
        codebuild.start_build(
            projectName=PROJECT_NAME, environmentVariablesOverride=params
        )
    except Exception as e:
        logger.exception("Failed to start build")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "An internal server error occurred"}),
        }

    return {"statusCode": 200, "body": json.dumps({"status": "started"})}
