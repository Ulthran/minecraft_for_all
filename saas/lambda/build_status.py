import json
import logging

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codebuild = boto3.client("codebuild")


def handler(event, context):
    """Return the status of a CodeBuild job."""
    build_id = event.get("pathParameters", {}).get("id")
    if not build_id:
        return {"statusCode": 400, "body": json.dumps({"error": "missing id"})}

    logger.info("Checking build status for %s", build_id)

    try:
        resp = codebuild.batch_get_builds(ids=[build_id])
    except Exception:
        logger.exception("Failed to query build status")
        return {"statusCode": 500, "body": json.dumps({"error": "internal"})}

    builds = resp.get("builds", [])
    if not builds:
        return {"statusCode": 404, "body": json.dumps({"error": "not found"})}

    build = builds[0]
    body = {
        "build": {
            "id": build.get("id"),
            "status": build.get("buildStatus"),
            "current_phase": build.get("currentPhase"),
        }
    }
    logger.info(
        "Build %s status retrieved: %s",
        build.get("id"),
        build.get("buildStatus"),
    )
    return {"statusCode": 200, "body": json.dumps(body)}
