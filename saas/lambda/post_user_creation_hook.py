import uuid
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """Add a unique identifier to the user after signup confirmation."""
    user_pool_id = event["userPoolId"]
    username = event["userName"]

    cognito_client = boto3.client("cognito-idp")

    try:
        cognito_client.admin_update_user_attributes(
            UserPoolId=user_pool_id,
            Username=username,
            UserAttributes=[{"Name": "custom:tenant_id", "Value": str(uuid.uuid4())}],
        )
    except Exception as e:
        logger.error(
            "Failed to update user attributes for user %s in pool %s: %s",
            username,
            user_pool_id,
            str(e),
        )
        raise

    logger.debug("Returning event: %s", event)

    return event
