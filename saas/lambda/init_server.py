import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codebuild = boto3.client("codebuild")
PROJECT_NAME = os.environ.get("PROJECT_NAME", "minecraft-tenant-terraform")
SERVER_TABLE = os.environ.get("SERVER_TABLE")
dynamodb = boto3.client("dynamodb")

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

    server_id = body.get("server_id")
    if server_id is None:
        if not SERVER_TABLE:
            return {
                "statusCode": 500,
                "body": json.dumps({"error": "server registry not configured"}),
            }
        try:
            resp = dynamodb.query(
                TableName=SERVER_TABLE,
                KeyConditionExpression="tenant_id = :t",
                ExpressionAttributeValues={":t": {"S": tenant_id}},
                ProjectionExpression="server_id",
                ScanIndexForward=False,
                Limit=1,
            )
            items = resp.get("Items", [])
            if items:
                server_id = str(int(items[0]["server_id"]["N"]) + 1)
            else:
                server_id = "1"
        except Exception:
            logger.exception("Failed to derive server id")
            return {"statusCode": 500, "body": json.dumps({"error": "internal"})}

    server_type = body.get("server_type", "papermc")
    if server_type not in ALLOWED_SERVER_TYPES:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid server_type"})}

    instance_type = body.get("instance_type", "t4g.medium")
    if instance_type not in ALLOWED_INSTANCE_TYPES:
        return {"statusCode": 400, "body": json.dumps({"error": "invalid instance_type"})}

    try:
        overworld_border = int(body.get("overworld_border", 3000))
    except (TypeError, ValueError):
        return {"statusCode": 400, "body": json.dumps({"error": "overworld_border must be an integer"})}
    if not MIN_BORDER <= overworld_border <= MAX_BORDER:
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"error": f"overworld_border must be between {MIN_BORDER} and {MAX_BORDER}"}
            ),
        }

    try:
        nether_border = int(body.get("nether_border", 3000))
    except (TypeError, ValueError):
        return {"statusCode": 400, "body": json.dumps({"error": "nether_border must be an integer"})}
    if not MIN_BORDER <= nether_border <= MAX_BORDER:
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"error": f"nether_border must be between {MIN_BORDER} and {MAX_BORDER}"}
            ),
        }

    server_name = body.get("name")

    params = [
        {"name": "TENANT_ID", "value": tenant_id, "type": "PLAINTEXT"},
        {"name": "SERVER_ID", "value": server_id, "type": "PLAINTEXT"},
        {"name": "SERVER_TYPE", "value": server_type, "type": "PLAINTEXT"},
        {"name": "INSTANCE_TYPE", "value": instance_type, "type": "PLAINTEXT"},
        {"name": "OVERWORLD_BORDER", "value": str(overworld_border), "type": "PLAINTEXT"},
        {"name": "NETHER_BORDER", "value": str(nether_border), "type": "PLAINTEXT"},
    ]

    if server_name:
        params.append({"name": "SERVER_NAME", "value": server_name, "type": "PLAINTEXT"})

    try:
        build_resp = codebuild.start_build(
            projectName=PROJECT_NAME, environmentVariablesOverride=params
        )
    except Exception as e:
        logger.exception("Failed to start build")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "An internal server error occurred"}),
        }

    build_id = build_resp.get("build", {}).get("id")
    body = {"status": "started"}
    if build_id:
        body["build_id"] = build_id

    return {"statusCode": 200, "body": json.dumps(body)}
