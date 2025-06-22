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

The `saas` directory contains Terraform configuration for creating tenant AWS accounts and a Cognito user pool for authentication. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and update the values. Run `terraform -chdir=saas init` once to download the providers and modules, then you can use `terraform -chdir=saas validate` or `terraform -chdir=saas apply` from a management account that has access to AWS Organizations.

### SaaS Website

The `saas_web` folder now contains the main SaaS site with signup, login and a
simple management console. Terraform creates a **private** S3 bucket and a
CloudFront distribution using an Origin Access Identity when
`frontend_bucket_name` is set. The website files are uploaded automatically
during `terraform apply`. The `SIGNUP_API_URL` and `LOGIN_API_URL` placeholders
in the Vue components are replaced with endpoints derived from the Cognito user
pool so no additional variables are needed. The console obtains the cost, start
and status endpoints from the tenant infrastructure after a user logs in, so
those placeholders remain unchanged.

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
`/COST_API_URL` used on the console page.
