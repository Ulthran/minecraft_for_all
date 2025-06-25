import logging
import uuid
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)



def handler(event, context):
    """Create a new tenant account when a user is confirmed."""
    logger.debug("Received event: %s", event)
    try:
        email = event["request"]["userAttributes"]["email"]
    except KeyError:
        logger.error("Email not found in event")
        return event

    tenant_id = f"{uuid.uuid4().hex[:8]}-{datetime.utcnow().strftime('%y%m%d%H%M')}"
    logger.info("Assigned tenant id %s to %s", tenant_id, email)

    event.setdefault("response", {})["tenant_info"] = {
        "tenant_id": tenant_id,
    }

    
    logger.debug("Returning event: %s", event)

    return event
