import boto3
import logging
import uuid
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

cognito = boto3.client("cognito-idp")



def handler(event, context):
    """Create a new tenant account when a user is confirmed."""
    logger.debug("Received event: %s", event)
    try:
        email = event["request"]["userAttributes"]["email"]
    except KeyError:
        logger.error("Email not found in event")
        return event

    try:
        user_pool_id = event["userPoolId"]
    except KeyError:
        logger.error("userPoolId not found in event")
        return event

    try:
        username = event["userName"]
    except KeyError:
        logger.error("userName not found in event")
        return event


    tenant_id = f"{uuid.uuid4().hex[:8]}-{datetime.utcnow().strftime('%y%m%d%H%M')}"
    logger.info("Assigned tenant id %s to %s", tenant_id, email)

    event.setdefault("response", {})["tenant_info"] = {
        "tenant_id": tenant_id,
    }

    # Persist the new tenant ID
    try:
        cognito.admin_update_user_attributes(
            UserPoolId=user_pool_id,
            Username=username,
            UserAttributes=[
                {"Name": "custom:tenant_id", "Value": tenant_id},
            ],
        )
        logger.info("Stored tenant id for %s", username)
    except Exception:
        logger.exception("Failed to set default attributes for %s", username)
        return { "statusCode": 500, "body": "Failed to set default attributes" }
    
    logger.debug("Returning event: %s", event)

    return event
