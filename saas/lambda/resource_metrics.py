import json
import logging
from datetime import datetime, timedelta

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")
cloudwatch = boto3.client("cloudwatch")


def get_sum(metric):
    datapoints = metric.get("Datapoints", [])
    if not datapoints:
        return 0.0
    # return most recent datapoint
    return sorted(datapoints, key=lambda d: d["Timestamp"], reverse=True)[0].get("Sum", 0.0)


def handler(event, context):
    """Return basic EC2 and EBS metrics for the tenant's server."""
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
        body = {"network_in": 0.0, "network_out": 0.0, "volumes": []}
        return {"statusCode": 200, "body": json.dumps(body)}

    instance = reservations[0]["Instances"][0]
    instance_id = instance["InstanceId"]

    now = datetime.utcnow()
    start = now - timedelta(hours=1)

    try:
        net_in = cloudwatch.get_metric_statistics(
            Namespace="AWS/EC2",
            MetricName="NetworkIn",
            Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
            StartTime=start,
            EndTime=now,
            Period=3600,
            Statistics=["Sum"],
        )
        net_out = cloudwatch.get_metric_statistics(
            Namespace="AWS/EC2",
            MetricName="NetworkOut",
            Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
            StartTime=start,
            EndTime=now,
            Period=3600,
            Statistics=["Sum"],
        )
        network_in = get_sum(net_in)
        network_out = get_sum(net_out)
    except Exception:
        logger.exception("Failed to get network metrics")
        network_in = 0.0
        network_out = 0.0

    try:
        vols = ec2.describe_volumes(
            Filters=[
                {"Name": "tag:tenant_id", "Values": [tenant_id]},
                {"Name": "tag:server_id", "Values": [server_id]},
            ]
        )
    except Exception:
        logger.exception("Failed to describe volumes")
        return {"statusCode": 500, "body": json.dumps({"error": "failed to query volumes"})}

    volumes = []
    for v in vols.get("Volumes", []):
        vol_id = v["VolumeId"]
        size_gb = v.get("Size")
        try:
            read = cloudwatch.get_metric_statistics(
                Namespace="AWS/EBS",
                MetricName="VolumeReadBytes",
                Dimensions=[{"Name": "VolumeId", "Value": vol_id}],
                StartTime=start,
                EndTime=now,
                Period=3600,
                Statistics=["Sum"],
            )
            write = cloudwatch.get_metric_statistics(
                Namespace="AWS/EBS",
                MetricName="VolumeWriteBytes",
                Dimensions=[{"Name": "VolumeId", "Value": vol_id}],
                StartTime=start,
                EndTime=now,
                Period=3600,
                Statistics=["Sum"],
            )
            read_bytes = get_sum(read)
            write_bytes = get_sum(write)
        except Exception:
            logger.exception("Failed to get volume metrics")
            read_bytes = 0.0
            write_bytes = 0.0
        volumes.append(
            {
                "id": vol_id,
                "size_gb": size_gb,
                "read_bytes": read_bytes,
                "write_bytes": write_bytes,
            }
        )

    body = {"network_in": network_in, "network_out": network_out, "volumes": volumes}
    return {"statusCode": 200, "body": json.dumps(body)}
