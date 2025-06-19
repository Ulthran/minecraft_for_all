import boto3
import os
import json
import urllib.request

INSTANCE_ID = os.environ.get("INSTANCE_ID")
SERVER_IP = os.environ.get("SERVER_IP")

ec2 = boto3.client("ec2")

def handler(event, context):
    try:
        resp = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
        state = resp["Reservations"][0]["Instances"][0]["State"]["Name"]
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    players = None
    if state == "running" and SERVER_IP:
        try:
            with urllib.request.urlopen(f"https://api.mcstatus.io/v2/status/java/{SERVER_IP}") as f:
                data = json.load(f)
                players = data.get("players", {}).get("online")
        except Exception:
            players = None

    return {
        "statusCode": 200,
        "body": json.dumps({"state": state, "players": players})
    }
