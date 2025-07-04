import boto3
import json
import os
from datetime import date, timedelta, datetime
from decimal import Decimal
import logging

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

ce = boto3.client("ce")
dynamodb = boto3.resource("dynamodb")
cost_table_name = os.environ.get("COST_TABLE")
cost_table = dynamodb.Table(cost_table_name) if cost_table_name else None


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
    start_date = today.replace(day=1)
    start = start_date.strftime("%Y-%m-%d")
    month_key = start_date.strftime("%Y-%m")
    # Cost Explorer requires the end date to be strictly after the start date.
    # The end date is exclusive, so use tomorrow's date to include today's cost
    # when the function runs on the first day of the month.
    end = (today + timedelta(days=1)).strftime("%Y-%m-%d")

    if cost_table:
        try:
            resp = cost_table.get_item(Key={"tenant_id": tenant_id, "month": month_key})
            item = resp.get("Item")
            logger.debug("Cache lookup result: %s", item)
            if item:
                last = item.get("last_updated")
                if last and datetime.fromisoformat(last).date() >= today - timedelta(days=1):
                    logger.info("Returning cached cost data")
                    return {
                        "statusCode": 200,
                        "body": json.dumps(
                            {
                                "total": float(item.get("total", 0)),
                                "breakdown": {k: float(v) for k, v in item.get("breakdown", {}).items()},
                            }
                        ),
                    }
        except Exception:
            logger.exception("Failed to read cost cache")
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

    logger.debug("Cost Explorer response: %s", resp)

    result = resp["ResultsByTime"][0]
    total = float(result["Total"]["UnblendedCost"]["Amount"])
    breakdown = {
        g["Keys"][0]: float(g["Metrics"]["UnblendedCost"]["Amount"])
        for g in result.get("Groups", [])
    }

    if cost_table:
        try:
            ttl = int((datetime.utcnow() + timedelta(days=2)).timestamp())
            cost_table.put_item(
                Item={
                    "tenant_id": tenant_id,
                    "month": month_key,
                    "last_updated": today.isoformat(),
                    "expires_at": ttl,
                    "total": Decimal(str(total)),
                    "breakdown": {k: Decimal(str(v)) for k, v in breakdown.items()},
                }
            )
        except Exception:
            logger.exception("Failed to store cost cache")
    return {
        "statusCode": 200,
        "body": json.dumps({"total": total, "breakdown": breakdown}),
    }
