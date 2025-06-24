# Minecraft Server Infrastructure

Minecraft server SaaS with AWS.

## Usage

### Terraform

```
cd terraform
terraform init    # downloads providers
terraform apply   # creates resources (requires AWS credentials)
```

Terraform variables are defined in `variables.tf`. Copy `terraform.tfvars.example`
to `terraform.tfvars` and fill in your values before running `terraform apply`.

## Testing

Basic checks run automatically via GitHub Actions whenever you push changes.
Separate workflows validate the standalone server Terraform configuration, the
SaaS Terraform layer and the two static sites. The Terraform workflows format
and validate their directories, while the server workflow also runs ShellCheck
and compiles the Lambda code. The site workflows validate the HTML using
`html5validator`. You can run the main Terraform checks locally if desired:

```
terraform fmt -check -recursive
terraform -chdir=terraform init
terraform -chdir=terraform validate
shellcheck terraform/user_data.sh
python3 -m py_compile terraform/lambda/start_minecraft.py
```

`terraform validate` may fail if provider plugins cannot be downloaded due to
network restrictions.

## SaaS Architecture

A design proposal for running each tenant in a separate AWS account is available in [docs/saas_layer.md](docs/saas_layer.md).

Step-by-step instructions for deploying the SaaS site and tenant provisioning Lambda are provided in [docs/saas_setup.md](docs/saas_setup.md).

The same Terraform layer also provisions a CodeBuild project in the management account. The build assumes a role in the target tenant account when started, so no tenant information is needed until execution time.
The `saas` directory contains Terraform configuration for creating tenant AWS accounts and a Cognito user pool for authentication. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and update the values. Run `terraform -chdir=saas init` once to download the providers and modules, then you can use `terraform -chdir=saas validate` or `terraform -chdir=saas apply` from a management account that has access to AWS Organizations.

### SaaS Website

The `saas_web` folder now contains the main SaaS site with signup, login and a
simple management console. Terraform creates a **private** S3 bucket and a
CloudFront distribution using an Origin Access Identity when
`frontend_bucket_name` is set. The website files are uploaded automatically
during `terraform apply`. The website files also receive the Cognito user pool
ID and client ID which are inserted into a small helper module. The signup,
verification and login components use the Amazon Cognito JavaScript SDK instead
of raw API requests. The console reads the cost, start and status endpoints from
custom attributes on the Cognito user after logging in using `vue-jwt-decode` to
parse the token, so no manual placeholder replacement is required.

Example `terraform.tfvars` entries:

```hcl
frontend_bucket_name = "example-landing-bucket"
```


To run the SaaS site locally,
option:

```bash
python3 dev_server.py
```

This serves the files from `saas_web` and mocks the various API endpoints so the
forms and console can be tested without deploying any backend, including a dummy
`/MC_API/cost` used on the console page.
