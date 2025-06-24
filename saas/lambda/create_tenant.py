import boto3
import logging
import os
import time
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

org = boto3.client("organizations")
cognito = boto3.client("cognito-idp")
dynamodb = boto3.resource("dynamodb")

EMAIL_DOMAIN = os.environ.get("EMAIL_DOMAIN")
if not EMAIL_DOMAIN:
    raise RuntimeError("EMAIL_DOMAIN environment variable must be set")
SCP_ID = os.environ.get("SCP_ID")
TENANT_OU_ID = os.environ.get("TENANT_OU_ID")

TENANT_OU_NAME = "MinecraftTenants"


def ensure_tenant_ou():
    """Return the root and OU IDs. Create the OU if needed and no ID set."""
    roots = org.list_roots()["Roots"]
    root_id = roots[0]["Id"]

    if TENANT_OU_ID:
        return root_id, TENANT_OU_ID

    paginator = org.get_paginator("list_organizational_units_for_parent")
    for page in paginator.paginate(ParentId=root_id):
        for ou in page["OrganizationalUnits"]:
            if ou["Name"] == TENANT_OU_NAME:
                return root_id, ou["Id"]

    resp = org.create_organizational_unit(ParentId=root_id, Name=TENANT_OU_NAME)
    ou_id = resp["OrganizationalUnit"]["Id"]
    logging.info("Created tenant OU %s", ou_id)
    return root_id, ou_id


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

    config = None
    try:
        table = dynamodb.Table(os.environ["CONFIG_TABLE"])
        resp = table.get_item(Key={"user_id": username})
        config = resp.get("Item")
        logger.info("Loaded pending config for %s", username)
    except Exception:
        logger.exception("Failed to load config for %s", username)

    tenant_id = str(uuid.uuid4())[:8]
    account_name = f"minecraft-{tenant_id}"
    root_id, ou_id = ensure_tenant_ou()

    account_email = f"{tenant_id}@{EMAIL_DOMAIN}"

    try:
        resp = org.create_account(Email=account_email, AccountName=account_name)
        create_id = resp["CreateAccountStatus"]["Id"]
        logger.info("Started account creation %s for %s", create_id, account_email)

        # Poll for completion briefly so the account can be moved into the tenant OU
        deadline = time.time() + 20
        while time.time() < deadline:
            status = org.describe_create_account_status(
                CreateAccountRequestId=create_id
            )["CreateAccountStatus"]
            if status["State"] == "SUCCEEDED":
                account_id = status["AccountId"]
                org.move_account(
                    AccountId=account_id,
                    SourceParentId=root_id,
                    DestinationParentId=ou_id,
                )
                logger.info("Moved account %s to OU %s", account_id, ou_id)
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
            "ou_id": ou_id,
        }
        if config:
            event["response"]["server_config"] = config
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
