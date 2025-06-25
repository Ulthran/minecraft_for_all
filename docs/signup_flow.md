# Signup to Provisioning Flow

This document outlines how account creation data and server configuration flow through the system from the initial signup form to infrastructure provisioning. It also notes where payment integration can be inserted in the future.

## 1. Collecting Signup Data

The landing page uses `saas_web/components/Start.vue` for new user registration. Besides the email and password fields, additional configuration such as player count and optional whitelisted players is collected. These values can be stored in a DynamoDB table keyed by the user name. Initially we considered passing them through Cognito custom attributes, but those have strict size limits. The SaaS layer now provisions a table named `minecraft-configs` with the following fields:

- **server_type** - vanilla or papermc
- **instance_type** - EC2 instance type
- **whitelisted_players** - list of strings
- **mods** - list of strings
- **overworld_border** - int
- **nether_border** - int
- **end_border** - int

More fields can be added later without altering the signup flow.

When a user signs up the frontend calls a small API (or Lambda function) that writes these values to the table using the Cognito username as the primary key. An abbreviated example using the AWS SDK:

```javascript
const attributeList = [
  new AmazonCognitoIdentity.CognitoUserAttribute({ Name: 'email', Value: email }),
];

await fetch('/config', { method: 'POST', body: JSON.stringify({
  user_id: email,
  server_type,
  instance_type,
  whitelisted_players,
  mods,
  overworld_border,
  nether_border,
  end_border,
}) });
```
Storing the configuration in DynamoDB avoids Cognito's 2048 character limit for custom attributes and keeps the signup form flexible.

## 2. Post‑Verification Hook

`saas/lambda/create_tenant.py` runs when the user confirms their account. The function generates a tenant identifier by combining a short UUID with the current timestamp and includes it in the Lambda response. It can also read the custom attributes or look up the pending configuration in DynamoDB. The values are included when triggering the CodeBuild provisioning project:

```python
codebuild.start_build(
    projectName='tenant-terraform',
    environmentVariablesOverride=[
        { 'name': 'TENANT_ID', 'value': tenant_id, 'type': 'PLAINTEXT' },
        { 'name': 'PLAYER_COUNT', 'value': players, 'type': 'PLAINTEXT' },
        { 'name': 'WHITELISTED_PLAYERS', 'value': ','.join(whitelisted_players), 'type': 'PLAINTEXT' },
    ],
)
```

The build spec then passes these variables to Terraform so the infrastructure matches the selected options.

The tenant identifier is passed along during provisioning rather than being
stored in Cognito. The console retains this value locally to derive the API
endpoint URLs.

## 3. Payment Integration

A future step between account confirmation and starting CodeBuild can require the user to set up billing (for example with Stripe). The post‑confirmation Lambda can place the new account into a **pending** state and send the user to a payment page. Once Stripe confirms a successful setup, the provisioning build is triggered with the stored configuration.

This approach keeps signup quick while ensuring infrastructure is only created for verified and paying customers.
