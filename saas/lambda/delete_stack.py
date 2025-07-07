import json
import logging
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codebuild = boto3.client("codebuild")
PROJECT_NAME = os.environ.get("PROJECT_NAME", "minecraft-tenant-terraform")


def handler(event, context):
    """Trigger CodeBuild to destroy the tenant stack."""
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
        body = {}
    server_id = body.get("server_id")
    if not server_id:
        return {"statusCode": 400, "body": json.dumps({"error": "missing server_id"})}

    params = [
        {"name": "TENANT_ID", "value": tenant_id, "type": "PLAINTEXT"},
        {"name": "SERVER_ID", "value": server_id, "type": "PLAINTEXT"},
        {"name": "ACTION", "value": "destroy", "type": "PLAINTEXT"},
    ]

    try:
        codebuild.start_build(projectName=PROJECT_NAME, environmentVariablesOverride=params)
    except botocore.exceptions.ClientError as e:
        logger.exception(f"ClientError while starting destroy build: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": "AWS ClientError"})}
    except Exception as e:
        logger.exception(f"Unexpected error while starting destroy build: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": "internal"})}

    return {"statusCode": 200, "body": json.dumps({"status": "started"})}

