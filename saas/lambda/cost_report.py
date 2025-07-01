import boto3
import json
from datetime import date, timedelta
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ce = boto3.client("ce")


def handler(event, context):
    """Return this month's accumulated cost for the tenant."""
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    tenant_id = claims.get("custom:tenant_id")
    if not tenant_id:
        logger.error("Missing tenant_id in claims")
        return {"statusCode": 400, "body": json.dumps({"error": "Missing tenant_id"})}
    today = date.today()
    start = today.replace(day=1).strftime("%Y-%m-%d")
    # Cost Explorer requires the end date to be strictly after the start date.
    # The end date is exclusive, so use tomorrow's date to include today's cost
    # when the function runs on the first day of the month.
    end = (today + timedelta(days=1)).strftime("%Y-%m-%d")
    try:
        params = {
            "TimePeriod": {"Start": start, "End": end},
            "Granularity": "MONTHLY",
            "Metrics": ["UnblendedCost"],
            "GroupBy": [{"Type": "DIMENSION", "Key": "SERVICE"}],
        }
        if tenant_id:
            params["Filter"] = {
                "Tags": {
                    "Key": "tenant_id",
                    "Values": [tenant_id],
                }
            }
        resp = ce.get_cost_and_usage(**params)
    except Exception:
        logger.exception("Failed to query cost explorer")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Could not retrieve cost"}),
        }

    result = resp["ResultsByTime"][0]
    total = float(result["Total"]["UnblendedCost"]["Amount"])
    breakdown = {
        g["Keys"][0]: float(g["Metrics"]["UnblendedCost"]["Amount"])
        for g in result.get("Groups", [])
    }
    return {
        "statusCode": 200,
        "body": json.dumps({"total": total, "breakdown": breakdown}),
    }
