import json
import os
import logging
import http.client
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY", "")


def handler(event, context):
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )
    tenant_id = claims.get("custom:tenant_id")
    if not tenant_id:
        return {"statusCode": 400, "body": json.dumps({"error": "missing tenant_id"})}

    logger.info("Creating checkout session for tenant %s", tenant_id)

    params = urllib.parse.urlencode({
        "metadata[tenant_id]": tenant_id,
    })
    conn = http.client.HTTPSConnection("api.stripe.com")
    headers = {
        "Authorization": f"Bearer {SECRET_KEY}",
        "Content-Type": "application/x-www-form-urlencoded",
    }
    try:
        conn.request("POST", "/v1/customers", params, headers)
        resp = conn.getresponse()
        data = json.loads(resp.read().decode())
        if resp.status >= 400:
            error_details = data.get("error", {}).get("message", "stripe_error")
            return {"statusCode": 502, "body": json.dumps({"error": error_details})}
        customer_id = data.get("id")

        intent_params = urllib.parse.urlencode(
            {
                "customer": customer_id,
                "usage": "off_session",
            }
        )
        conn.request("POST", "/v1/setup_intents", intent_params, headers)
        intent_resp = conn.getresponse()
        intent_data = json.loads(intent_resp.read().decode())
        if intent_resp.status >= 400:
            error_details = intent_data.get("error", {}).get("message", "stripe_error")
            return {"statusCode": 502, "body": json.dumps({"error": error_details})}
        client_secret = intent_data.get("client_secret")
        logger.info("Checkout session created for tenant %s", tenant_id)
        return {"statusCode": 200, "body": json.dumps({"client_secret": client_secret})}
    except Exception:
        logger.exception("Stripe request failed")
        return {"statusCode": 500, "body": json.dumps({"error": "internal"})}
