import boto3
import json
import os
from datetime import date, timedelta, datetime
from decimal import Decimal
import logging

INSTANCE_RATES = {
    "t4g.small": 0.0168,
    "t4g.medium": 0.0336,
    "t3.large": 0.0832,
}

EBS_RATE = 0.08  # per GB-month
DATA_TRANSFER_RATE = 0.09
FREE_TRANSFER_GB = 1
S3_RATE = 0.023  # per GB-month

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
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
    logger.info("Generating cost report for tenant %s", tenant_id)
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
    end_time = datetime.utcnow()
    month_end = (start_date + timedelta(days=32)).replace(day=1)
    seconds_in_month = (month_end - datetime.combine(start_date, datetime.min.time())).total_seconds()
    elapsed_seconds = (end_time - datetime.combine(start_date, datetime.min.time())).total_seconds()

    compute_cost = 0.0
    network_bytes = 0

    ec2 = boto3.client("ec2")
    cw = boto3.client("cloudwatch")
    s3 = boto3.client("s3")

    try:
        resp = ec2.describe_instances(
            Filters=[{"Name": "tag:tenant_id", "Values": [tenant_id]}]
        )
    except Exception:
        logger.exception("Failed to describe instances")
        resp = {"Reservations": []}

    for res in resp.get("Reservations", []):
        for inst in res.get("Instances", []):
            inst_id = inst["InstanceId"]
            inst_type = inst.get("InstanceType")
            rate = INSTANCE_RATES.get(inst_type, 0)
            try:
                cpu = cw.get_metric_statistics(
                    Namespace="AWS/EC2",
                    MetricName="CPUUtilization",
                    Dimensions=[{"Name": "InstanceId", "Value": inst_id}],
                    StartTime=start_date,
                    EndTime=end_time,
                    Period=3600,
                    Statistics=["Average"],
                )
                hours = len(cpu.get("Datapoints", []))
            except Exception:
                logger.exception("Failed to get CPU metrics")
                hours = 0
            compute_cost += hours * rate

            try:
                net = cw.get_metric_statistics(
                    Namespace="AWS/EC2",
                    MetricName="NetworkOut",
                    Dimensions=[{"Name": "InstanceId", "Value": inst_id}],
                    StartTime=start_date,
                    EndTime=end_time,
                    Period=3600,
                    Statistics=["Sum"],
                )
                network_bytes += sum(dp.get("Sum", 0) for dp in net.get("Datapoints", []))
            except Exception:
                logger.exception("Failed to get network metrics")

    try:
        vols = ec2.describe_volumes(
            Filters=[{"Name": "tag:tenant_id", "Values": [tenant_id]}]
        )
        total_gb = sum(v.get("Size", 0) for v in vols.get("Volumes", []))
    except Exception:
        logger.exception("Failed to describe volumes")
        total_gb = 0

    elapsed_fraction = elapsed_seconds / seconds_in_month if seconds_in_month else 0
    ebs_cost = total_gb * EBS_RATE * elapsed_fraction

    backup_bucket = os.environ.get("BACKUP_BUCKET", "minecraft-saas-backups")
    backup_bytes = 0
    try:
        paginator = s3.get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=backup_bucket, Prefix=f"{tenant_id}/"):
            for obj in page.get("Contents", []):
                backup_bytes += obj.get("Size", 0)
    except Exception:
        logger.exception("Failed to list backup objects")

    s3_cost = (backup_bytes / (1024 ** 3)) * S3_RATE * elapsed_fraction

    network_gb = network_bytes / (1024 ** 3)
    network_cost = max(0.0, network_gb - FREE_TRANSFER_GB) * DATA_TRANSFER_RATE

    total = compute_cost + network_cost + ebs_cost + s3_cost
    breakdown = {
        "compute": round(compute_cost, 2),
        "network": round(network_cost, 2),
        "storage": round(ebs_cost + s3_cost, 2),
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
    logger.info(
        "Cost report generated for tenant %s: total=%s",
        tenant_id,
        total,
    )
    return {
        "statusCode": 200,
        "body": json.dumps({"total": total, "breakdown": breakdown}),
    }
