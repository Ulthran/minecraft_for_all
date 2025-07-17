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
CACHE_TTL_HOURS = 1

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
    end = (today + timedelta(days=1)).strftime("%Y-%m-%d")

    end_time = datetime.utcnow()
    month_end = (start_date + timedelta(days=32)).replace(day=1)
    seconds_in_month = (month_end - datetime.combine(start_date, datetime.min.time())).total_seconds()
    elapsed_seconds = (end_time - datetime.combine(start_date, datetime.min.time())).total_seconds()

    ec2 = boto3.client("ec2")
    cw = boto3.client("cloudwatch")
    s3 = boto3.client("s3")

    # Discover all servers for the tenant
    try:
        resp = ec2.describe_instances(Filters=[{"Name": "tag:tenant_id", "Values": [tenant_id]}])
    except Exception:
        logger.exception("Failed to describe instances")
        resp = {"Reservations": []}

    servers = {}
    for res in resp.get("Reservations", []):
        for inst in res.get("Instances", []):
            server_id = "unknown"
            for tag in inst.get("Tags", []):
                if tag.get("Key") == "server_id":
                    server_id = tag.get("Value")
                    break
            servers.setdefault(server_id, []).append(inst)

    server_costs = {}
    totals = {"compute": 0.0, "network": 0.0, "storage": 0.0, "backup": 0.0}

    for server_id, instances in servers.items():
        cached = None
        if cost_table:
            try:
                resp = cost_table.get_item(Key={"tenant_id": tenant_id, "server_id": server_id})
                cached = resp.get("Item")
            except Exception:
                logger.exception("Failed to read cost cache")

        if cached:
            last = cached.get("last_updated")
            try:
                last_dt = datetime.fromisoformat(last)
            except Exception:
                last_dt = None
            if last_dt and (datetime.utcnow() - last_dt).total_seconds() < CACHE_TTL_HOURS * 3600 and cached.get("month") == month_key:
                comp = float(cached.get("compute", 0))
                net = float(cached.get("network", 0))
                stor = float(cached.get("storage", 0))
                back = float(cached.get("backup", 0))
                tot = float(cached.get("total", 0))
                server_costs[server_id] = tot
                totals["compute"] += comp
                totals["network"] += net
                totals["storage"] += stor
                totals["backup"] += back
                continue

        compute = 0.0
        net_bytes = 0

        for inst in instances:
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
            compute += hours * rate

            try:
                net_resp = cw.get_metric_statistics(
                    Namespace="AWS/EC2",
                    MetricName="NetworkOut",
                    Dimensions=[{"Name": "InstanceId", "Value": inst_id}],
                    StartTime=start_date,
                    EndTime=end_time,
                    Period=3600,
                    Statistics=["Sum"],
                )
                net_bytes += sum(dp.get("Sum", 0) for dp in net_resp.get("Datapoints", []))
            except Exception:
                logger.exception("Failed to get network metrics")

        try:
            vols = ec2.describe_volumes(
                Filters=[
                    {"Name": "tag:tenant_id", "Values": [tenant_id]},
                    {"Name": "tag:server_id", "Values": [server_id]},
                ]
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
            prefix = f"{tenant_id}/{server_id}/"
            for page in paginator.paginate(Bucket=backup_bucket, Prefix=prefix):
                for obj in page.get("Contents", []):
                    backup_bytes += obj.get("Size", 0)
        except Exception:
            logger.exception("Failed to list backup objects")

        s3_cost = (backup_bytes / (1024 ** 3)) * S3_RATE * elapsed_fraction

        network_gb = net_bytes / (1024 ** 3)
        network_cost = max(0.0, network_gb - FREE_TRANSFER_GB) * DATA_TRANSFER_RATE

        total = compute + network_cost + ebs_cost + s3_cost

        totals["compute"] += compute
        totals["network"] += network_cost
        totals["storage"] += ebs_cost
        totals["backup"] += s3_cost
        server_costs[server_id] = total

        if cost_table:
            try:
                ttl = int((datetime.utcnow() + timedelta(hours=CACHE_TTL_HOURS)).timestamp())
                cost_table.put_item(
                    Item={
                        "tenant_id": tenant_id,
                        "server_id": server_id,
                        "month": month_key,
                        "last_updated": datetime.utcnow().isoformat(),
                        "expires_at": ttl,
                        "total": Decimal(str(total)),
                        "compute": Decimal(str(compute)),
                        "network": Decimal(str(network_cost)),
                        "storage": Decimal(str(ebs_cost)),
                        "backup": Decimal(str(s3_cost)),
                    }
                )
            except Exception:
                logger.exception("Failed to store cost cache")

    total_cost = totals["compute"] + totals["network"] + totals["storage"] + totals["backup"]
    breakdown = {
        "compute": round(totals["compute"], 2),
        "network": round(totals["network"], 2),
        "storage": round(totals["storage"], 2),
        "backup": round(totals["backup"], 2),
    }

    logger.info("Cost report generated for tenant %s", tenant_id)
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "total": round(total_cost, 2),
                "breakdown": breakdown,
                "servers": {k: round(v, 2) for k, v in server_costs.items()},
            }
        ),
    }
