import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")


def handler(event, context):
    """Return the current state of the tenant's Minecraft server."""
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    tenant_id = claims.get("custom:tenant_id")
    if not tenant_id:
        return {"statusCode": 400, "body": json.dumps({"error": "missing tenant_id"})}

    params = event.get("queryStringParameters") or {}
    server_id = params.get("server_id", "1")

    logger.info(
        "Checking server status for tenant %s server %s",
        tenant_id,
        server_id,
    )

    try:
        resp = ec2.describe_instances(
            Filters=[
                {"Name": "tag:tenant_id", "Values": [tenant_id]},
                {"Name": "tag:server_id", "Values": [server_id]},
            ]
        )
    except Exception:
        logger.exception("Failed to describe instances")
        return {"statusCode": 500, "body": json.dumps({"error": "failed to query"})}

    state = "offline"
    reservations = resp.get("Reservations", [])
    exists = bool(reservations)
    if reservations:
        instance = reservations[0]["Instances"][0]
        state = instance.get("State", {}).get("Name", "unknown")

    logger.info(
        "Server %s for tenant %s exists=%s state=%s",
        server_id,
        tenant_id,
        exists,
        state,
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"state": state, "exists": exists}),
    }

