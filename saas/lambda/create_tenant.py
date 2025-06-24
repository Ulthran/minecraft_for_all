import boto3
import logging
import os
import time
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

org = boto3.client("organizations")
cognito = boto3.client("cognito-idp")

EMAIL_DOMAIN = os.environ.get("EMAIL_DOMAIN")
if not EMAIL_DOMAIN:
    raise RuntimeError("EMAIL_DOMAIN environment variable must be set")
SCP_ID = os.environ.get("SCP_ID")


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


    tenant_id = str(uuid.uuid4())[:8]
    account_name = f"minecraft-{tenant_id}"

    account_email = f"{tenant_id}@{EMAIL_DOMAIN}"

    try:
        resp = org.create_account(Email=account_email, AccountName=account_name)
        create_id = resp["CreateAccountStatus"]["Id"]
        logger.info("Started account creation %s for %s", create_id, account_email)

        # Poll for completion briefly so the account can be initialized
        deadline = time.time() + 20
        while time.time() < deadline:
            status = org.describe_create_account_status(
                CreateAccountRequestId=create_id
            )["CreateAccountStatus"]
            if status["State"] == "SUCCEEDED":
                account_id = status["AccountId"]
                if SCP_ID:
                    org.attach_policy(PolicyId=SCP_ID, TargetId=account_id)
                    logger.info("Attached SCP %s to %s", SCP_ID, account_id)
                break
            if status["State"] == "FAILED":
                logger.error("Account creation failed: %s", status.get("FailureReason"))
                break
            time.sleep(5)

        event.setdefault("response", {})["tenant_info"] = {
            "tenant_id": tenant_id,
            "create_id": create_id,
        }
    except Exception:
        logger.exception("Failed to create account for %s", account_email)

    # Ensure custom attributes exist for API endpoints
    try:
        cognito.admin_update_user_attributes(
            UserPoolId=user_pool_id,
            Username=username,
            UserAttributes=[
                {"Name": "custom:mc_api_url", "Value": ""},
            ],
        )
        logger.info("Initialized custom attribute for %s", username)
    except Exception:
        logger.exception("Failed to set default attributes for %s", username)

    return event
