# SaaS Website Setup

This guide explains how to deploy the SaaS landing page and how new tenants are
provisioned when a user confirms their account.

## Deploying the Website

1. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and set
   `frontend_bucket_name` to the S3 bucket that will host the site.
2. Run `terraform -chdir=saas init` followed by `terraform -chdir=saas apply` from
   an AWS account with access to AWS Organizations. This creates the user pool,
   tenant provisioning Lambda and S3 bucket/CloudFront distribution for the website.
3. Upload the contents of the `saas_web` directory to the created S3 bucket and
   update the `*_API_URL` placeholders inside the Vue components to point at your
   deployed APIs.

## Local Development

To test the SaaS site locally without any AWS resources run:

```bash
python3 dev_server.py --site saas_web
```

This serves the site at <http://localhost:8000> and mocks all API endpoints so
signup, login and the console work offline.

## Tenant Provisioning Lambda

The `create_tenant` Lambda function (`saas/lambda/create_tenant.py`) is attached
as a *post confirmation* trigger on the Cognito user pool. When a new user
confirms their account the function uses the AWS Organizations API to create a
fresh member account for that tenant.

The function currently performs the following steps:

1. Read the confirmed user's email from the event.
2. Generate a short tenant identifier.
3. Ensure an organizational unit named `MinecraftTenants` exists.
4. Call `organizations.create_account` with the email and a default account name.
5. Once creation completes, move the new account into that organizational unit.

The `saas` Terraform code builds and deploys this Lambda automatically and
grants the user pool permission to invoke it.
