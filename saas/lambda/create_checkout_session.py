import json
import os
import logging
import http.client
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY", "")
PRICE_ID = os.environ.get("STRIPE_PRICE_ID", "")


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

        sub_params = urllib.parse.urlencode(
            {
                "customer": customer_id,
                "items[0][price]": PRICE_ID,
                "payment_behavior": "default_incomplete",
                "expand[]": "latest_invoice.payment_intent",
            }
        )
        conn.request("POST", "/v1/subscriptions", sub_params, headers)
        sub_resp = conn.getresponse()
        sub_data = json.loads(sub_resp.read().decode())
        if sub_resp.status >= 400:
            return {"statusCode": 502, "body": json.dumps({"error": "stripe_error"})}
        client_secret = (
            sub_data.get("latest_invoice", {})
            .get("payment_intent", {})
            .get("client_secret")
        )
        return {"statusCode": 200, "body": json.dumps({"client_secret": client_secret})}
    except Exception:
        logger.exception("Stripe request failed")
        return {"statusCode": 500, "body": json.dumps({"error": "internal"})}
