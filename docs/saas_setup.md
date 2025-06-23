# SaaS Website Setup

This guide explains how to deploy the SaaS landing page and how new tenants are
provisioned when a user confirms their account.

## Deploying the Website

1. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and set
   `frontend_bucket_name` to the S3 bucket that will host the site. The bucket
   remains private.
2. Run `terraform -chdir=saas init` followed by `terraform -chdir=saas apply` from
   an AWS account with access to AWS Organizations. This creates the user pool,
   tenant provisioning Lambda and a CloudFront distribution configured with an
   Origin Access Identity for the bucket.
3. `terraform -chdir=saas apply` will automatically upload the contents of
   `saas_web` to the created S3 bucket. The `SIGNUP_API_URL` and
   `LOGIN_API_URL` placeholders are filled in using values derived from the
   Cognito user pool. The console reads the cost, start and status endpoints
   from custom attributes on the Cognito user after login.

## Local Development

To test the SaaS site locally without any AWS resources run:

```bash
python3 dev_server.py --site saas_web
```

This serves the site at <http://localhost:8000> and mocks all API endpoints so
signup, login and the console work offline, including a fake cost API used on
the console page.

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

## Cost Reporting Lambda

Each tenant account also includes a simple `cost_report` Lambda function that is
exposed through an API Gateway endpoint. This function queries the AWS Cost
Explorer API for the current month's charges and returns the total along with a
breakdown by service. The console calls this endpoint after authenticating the
user; no manual placeholder replacement is required.
