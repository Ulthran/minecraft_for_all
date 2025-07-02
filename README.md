# Minecraft Server Infrastructure

Minecraft server SaaS with AWS.

## Usage

### Terraform


```
cd tenant
# initialize with the remote state bucket and lock table created by the SaaS layer
terraform init \
  -backend-config="bucket=YOUR_STATE_BUCKET" \
  -backend-config="key=YOUR_TENANT/terraform.tfstate" \
  -backend-config="dynamodb_table=YOUR_LOCK_TABLE"
terraform apply   # creates resources (requires AWS credentials)
```

Terraform variables are defined in `variables.tf`. Copy `terraform.tfvars.example`
to `terraform.tfvars` and fill in your values before running `terraform apply`.
The `tenant_id` variable is required but normally passed in automatically by
the provisioning pipeline.

## Testing

Basic checks run automatically via GitHub Actions whenever you push changes.
Separate workflows validate the standalone server Terraform configuration, the
SaaS Terraform layer and the two static sites. The Terraform workflows format
and validate their directories, while the server workflow also runs ShellCheck
and compiles the Lambda code. The site workflows validate the HTML using
`html5validator`. You can run the main Terraform checks locally if desired:

```
terraform fmt -check -recursive
terraform -chdir=tenant init
terraform -chdir=tenant validate
shellcheck tenant/user_data.sh
```

`terraform validate` may fail if provider plugins cannot be downloaded due to
network restrictions.

## SaaS Architecture

A design proposal for hosting all tenants in a single shared AWS account is available in [docs/saas_layer.md](docs/saas_layer.md).

Step-by-step instructions for deploying the SaaS site and tenant provisioning Lambda are provided in [docs/saas_setup.md](docs/saas_setup.md).

The same Terraform layer also provisions a CodeBuild project that applies Terraform in the shared tenant account. Since everything lives in one account, the build uses its own IAM role directly.
The `saas` directory contains Terraform configuration for creating the shared tenant AWS account and a Cognito user pool for authentication. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and update the values. Run `terraform -chdir=saas init` once to download the providers and modules, then you can use `terraform -chdir=saas validate` or `terraform -chdir=saas apply` from a management account that has access to AWS Organizations.

### SaaS Website

The `saas_web` folder now contains the main SaaS site with signup, login and a
simple management console. Terraform creates a **private** S3 bucket and a
CloudFront distribution using an Origin Access Identity when
`frontend_bucket_name` is set. The website files are uploaded automatically
during `terraform apply`. The website files also receive the Cognito user pool
ID and client ID which are inserted into a small helper module. The signup,
verification and login components use the Amazon Cognito JavaScript SDK instead
of raw API requests. After logging in the console simply includes the ID token
in requests to the API endpoint injected during deployment. The backend derives
the tenant identifier from the token so no manual placeholder replacement is
required.

Example `terraform.tfvars` entries:

```hcl
frontend_bucket_name = "example-landing-bucket"
backup_bucket_name  = "example-backup-bucket"
```


To run the SaaS site locally,
option:

```bash
python3 dev_server.py
```

This serves the files from `saas_web` and mocks the various API endpoints so the
forms and console can be tested without deploying any backend, including a dummy
`/MC_API/cost` used on the console page.

Debugging UI components is easier with dedicated routes:

```
http://localhost:8000/#/debug-payment
http://localhost:8000/#/debug-config
```

These load the payment and configuration steps in isolation so layout or API
issues can be inspected without navigating through the full wizard.
