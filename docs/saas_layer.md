# SaaS Architecture Overview

This document outlines a high level plan for supporting multiple tenants in a
single dedicated AWS account. Each tenant's resources are tagged and isolated
through IAM roles rather than separate AWS accounts.

## Tenant Account
- Use the `aws_organizations_account` resource to create a single account that hosts all tenant infrastructure.
- Resources for each tenant are tagged with a unique identifier so usage and billing can be tracked per customer.
- IAM roles restrict each tenant to only their tagged resources.
 - Each tenant still receives a dedicated VPC and EC2 instance within the shared account. World backups are stored in a shared S3 bucket managed by the SaaS layer instead of per-tenant buckets.

## Authentication
- Central authentication can be provided by Amazon Cognito in the management account.
- The web interface authenticates users and stores a tenant identifier (e.g. Cognito groups or a tenant table) so API requests target the correct account.

## Billing with Stripe
- Usage metrics (like server uptime or data transfer) should be aggregated in the management account using CloudWatch or AWS Cost Explorer.
- A billing service periodically reports usage to Stripe to invoice customers. Webhooks from Stripe can update account status (e.g. suspend on failed payment).

## Future Work
- Implement Terraform modules for account creation and per‑tenant infrastructure.
- Add automation for provisioning DNS and SSL certificates.
