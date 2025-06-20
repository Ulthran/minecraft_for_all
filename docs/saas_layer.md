# SaaS Architecture Overview

This document outlines a high level plan for supporting a multi‑tenant setup where each customer runs their Minecraft server in an isolated AWS account created with Terraform.

## Account Creation
- Use the `aws_organizations_account` resource from the AWS provider to create a new member account for each tenant.
- All tenant accounts are placed in an organizational unit called `MinecraftTenants` for easier management.
- After creation, Terraform can assume an IAM role in the new account (e.g. `OrganizationAccountAccessRole`) to deploy the server infrastructure.
- Each tenant account receives its own VPC, EC2 instance and web bucket. An Elastic IP is allocated so the server address stays constant.

## Authentication
- Central authentication can be provided by Amazon Cognito in the management account.
- The web interface authenticates users and stores a tenant identifier (e.g. Cognito groups or a tenant table) so API requests target the correct account.

## Billing with Stripe
- Usage metrics (like server uptime or data transfer) should be aggregated in the management account using CloudWatch or AWS Cost Explorer.
- A billing service periodically reports usage to Stripe to invoice customers. Webhooks from Stripe can update account status (e.g. suspend on failed payment).

## Future Work
- Implement Terraform modules for account creation and per‑tenant infrastructure.
- Add automation for provisioning DNS and SSL certificates.
