import boto3
import logging
import time
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

org = boto3.client("organizations")

TENANT_OU_NAME = "MinecraftTenants"


def ensure_tenant_ou():
    """Return the root and OU IDs, creating the OU if needed."""
    roots = org.list_roots()["Roots"]
    root_id = roots[0]["Id"]

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

    tenant_id = str(uuid.uuid4())[:8]
    account_name = f"minecraft-{tenant_id}"
    root_id, ou_id = ensure_tenant_ou()
    try:
        resp = org.create_account(Email=email, AccountName=account_name)
        create_id = resp["CreateAccountStatus"]["Id"]
        logger.info("Started account creation %s for %s", create_id, email)

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
    except Exception:
        logger.exception("Failed to create account for %s", email)

    return event
