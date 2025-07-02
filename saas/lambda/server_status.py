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

    try:
        resp = ec2.describe_instances(
            Filters=[{"Name": "tag:tenant_id", "Values": [tenant_id]}]
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

    return {
        "statusCode": 200,
        "body": json.dumps({"state": state, "exists": exists}),
    }

