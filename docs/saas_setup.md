# SaaS Website Setup

This guide explains how to deploy the SaaS landing page and how new tenants are
provisioned when a user confirms their account.

## Deploying the Website

1. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and set
   `frontend_bucket_name` to the S3 bucket that will host the site. The bucket
   remains private.
2. Run `terraform -chdir=saas init` followed by `terraform -chdir=saas apply` from
   an AWS account with access to AWS Organizations. This creates the user pool,
   a dedicated tenant account and the provisioning Lambda along with a CloudFront
   distribution for the site. No tenant information is required for this initial
   deployment.
3. `terraform -chdir=saas apply` will automatically upload the contents of
   `saas_web` to the created S3 bucket. The Cognito user pool ID and client ID
   are injected directly into the Vue components so the frontend can use the
  Amazon Cognito JavaScript SDK. After login the console decodes the ID token
  with `vue-jwt-decode` and builds the cost, start and status URLs using the
  tenant identifier returned during signup.

## Local Development

To test the SaaS site locally without any AWS resources run:

```bash
python3 dev_server.py --site saas_web
```

This serves the site at <http://localhost:8000> and mocks all API endpoints so
signup, login and the console work offline, including a fake cost API used on
the console page.

## Post Confirmation Hook

The `post_user_creation_hook` Lambda function (`saas/lambda/post_user_creation_hook.py`)
is attached as a *post confirmation* trigger on the Cognito user pool. When a new
user confirms their account the function assigns a UUID to a custom attribute so
other services can uniquely reference the user.

The function performs the following steps:

1. Read the `userPoolId` and `userName` from the event.
2. Call Cognito's `AdminUpdateUserAttributes` API to set the `custom:uuid`
   attribute to a random value.

The `saas` Terraform code builds and deploys this Lambda automatically and
grants the user pool permission to invoke it.

On subsequent logins the console can retrieve the tenant identifier from its
stored configuration rather than the Cognito ID token.

## Cost Reporting Lambda

Each tenant account also includes a simple `cost_report` Lambda function that is
exposed through an API Gateway endpoint. This function queries the AWS Cost
Explorer API for the current month's charges and returns the total along with a
breakdown by service. The console calls this endpoint after authenticating the
user; no manual placeholder replacement is required.

## Provisioning Pipeline

After a tenant is registered the SaaS layer can run Terraform automatically using AWS CodeBuild. The `saas` configuration provisions a single CodeBuild project in the management account named `tenant-terraform`. The build deploys resources into the shared tenant account and tags everything with the provided tenant ID.

To provision infrastructure for a specific tenant, start a build and override the `TENANT_ID` environment variable so the tags are applied correctly.
