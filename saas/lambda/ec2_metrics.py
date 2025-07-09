import json
import logging
from datetime import datetime, timedelta

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")
cloudwatch = boto3.client("cloudwatch")


def get_average(metric):
    datapoints = metric.get("Datapoints", [])
    if not datapoints:
        return 0.0
    # Return most recent datapoint average
    return sorted(datapoints, key=lambda d: d["Timestamp"], reverse=True)[0].get(
        "Average", 0.0
    )


def handler(event, context):
    """Return EC2 CPU utilization for the tenant's server."""
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

    reservations = resp.get("Reservations", [])
    if not reservations:
        return {"statusCode": 404, "body": json.dumps({"error": "instance not found"})}

    instance_id = reservations[0]["Instances"][0]["InstanceId"]
    end = datetime.utcnow()
    start = end - timedelta(hours=1)

    try:
        cpu = cloudwatch.get_metric_statistics(
            Namespace="AWS/EC2",
            MetricName="CPUUtilization",
            Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
            StartTime=start,
            EndTime=end,
            Period=3600,
            Statistics=["Average"],
        )
        cpu_util = get_average(cpu)
    except Exception:
        logger.exception("Failed to get CPU metrics")
        cpu_util = 0.0

    body = {"cpu": cpu_util}
    return {"statusCode": 200, "body": json.dumps(body)}
