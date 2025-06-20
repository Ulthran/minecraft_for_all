import boto3
import logging
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

org = boto3.client("organizations")

def handler(event, context):
    """Create a new tenant account when a user is confirmed."""
    logger.debug("Received event: %s", event)
    try:
        email = event["request"]["userAttributes"]["email"]
    except KeyError:
        logger.error("Email not found in event")
        return event

    tenant_id = str(uuid.uuid4())[:8]
    account_name = f"minecraft-{tenant_id}"
    try:
        resp = org.create_account(Email=email, AccountName=account_name)
        create_id = resp["CreateAccountStatus"]["Id"]
        logger.info("Started account creation %s for %s", create_id, email)
        event.setdefault("response", {})["tenant_info"] = {
            "tenant_id": tenant_id,
            "create_id": create_id,
        }
    except Exception:
        logger.exception("Failed to create account for %s", email)

    return event
