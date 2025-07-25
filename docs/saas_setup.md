# SaaS Website Setup

This guide explains how to deploy the SaaS landing page and how new tenants are
provisioned when a user confirms their account.

## Deploying the Website

1. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and set
   `frontend_bucket_name` to the S3 bucket that will host the site and
   `backup_bucket_name` for the shared backup location. Both buckets remain
   private. The backup bucket should be organized using the structure
   `tenant_id/server_id/backup_timestamp/` so a single directory contains all
   files for one server.
2. Run `terraform -chdir=saas init` followed by `terraform -chdir=saas apply` from
   an AWS account with access to AWS Organizations. This creates the user pool,
   a dedicated tenant account and the provisioning Lambda along with a CloudFront
   distribution for the site. No tenant information is required for this initial
   deployment.
3. `terraform -chdir=saas apply` will automatically upload the contents of
   `saas_web` to the created S3 bucket. The Cognito user pool ID and client ID
   are injected directly into the Vue components so the frontend can use the
   Amazon Cognito JavaScript SDK. After login the console simply sends the ID
   token to the API endpoint injected during deployment and the backend
   determines the tenant from the JWT claims.

## Local Development

To test the SaaS site locally without any AWS resources run:

```bash
python3 dev_server.py --site saas_web
```

This serves the site at <http://localhost:8000> and mocks all API endpoints so
signup, login and the console work offline. The mocked cost API at
`/MC_API/cost` now returns example billing data including the total across all
servers, individual server totals and a breakdown per service.

## Post Confirmation Hook

The `post_user_creation_hook` Lambda function (`saas/lambda/post_user_creation_hook.py`)
is attached as a _post confirmation_ trigger on the Cognito user pool. When a new
user confirms their account the function assigns a UUID to a custom attribute so
other services can uniquely reference the user.

The function performs the following steps:

1. Read the `userPoolId` and `userName` from the event.
2. Call Cognito's `AdminUpdateUserAttributes` API to set the `custom:uuid`
   attribute to a random value.

The `saas` Terraform code builds and deploys this Lambda automatically and
grants the user pool permission to invoke it.

Because the tenant identifier is derived from the JWT, the console no longer
stores any tenant-specific API configuration.

## Cost Reporting Lambda

Each tenant account also includes a `cost_report` Lambda function exposed
through an API Gateway endpoint. The function collects instance, network,
EBS and S3 usage metrics from CloudWatch and calculates the estimated cost for
each server. Results are cached in DynamoDB for one hour per
`tenant_id`/`server_id` pair so repeated requests do not hit the AWS APIs
unnecessarily. The console reads this endpoint after authenticating the user,
so no manual placeholder replacement is required.

## Provisioning Pipeline

After a tenant is registered the SaaS layer can run Terraform automatically using AWS CodeBuild. The `saas` configuration provisions a single CodeBuild project in the management account named `tenant-terraform`. The build deploys resources into the shared tenant account and tags everything with the provided tenant ID.

To provision infrastructure for a specific tenant, start a build and override the `TENANT_ID` environment variable so the tags are applied correctly.
