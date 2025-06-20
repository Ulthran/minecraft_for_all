# Minecraft Server Infrastructure

This repo contains example infrastructure code for running a Minecraft server on AWS.
It includes both the original CloudFormation template and a Terraform setup with
an EC2 instance, S3 backups and a small Lambda function for starting the server.

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

## Web Interface

The `web` directory contains a very small single-page application that lets you
check the server status and start it when offline. The app is intended to be
deployed to an S3 bucket behind CloudFront. Terraform creates the bucket and
distribution when `web_bucket_name` is set.

After applying the Terraform configuration, upload the contents of the `web`
folder to the created bucket and replace the `STATUS_API_URL` and
`START_API_URL` placeholders in `app.js` with the values from the Terraform
outputs `status_minecraft_api_url` and `start_minecraft_api_url`.

### Local Testing

A helper script is provided for testing the web interface without AWS. Run:

```
python3 dev_server.py
```

This starts a server on `http://localhost:8000` that serves the files from the
`web` directory and provides dummy endpoints at `/STATUS_API_URL` and
`/START_API_URL`.

## SaaS Architecture

A design proposal for running each tenant in a separate AWS account is available in [docs/saas_layer.md](docs/saas_layer.md).

Step-by-step instructions for deploying the SaaS site and tenant provisioning Lambda are provided in [docs/saas_setup.md](docs/saas_setup.md).

The `saas` directory contains Terraform configuration for creating tenant AWS accounts and a Cognito user pool for authentication. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and update the values. Run `terraform -chdir=saas init` once to download the providers and modules, then you can use `terraform -chdir=saas validate` or `terraform -chdir=saas apply` from a management account that has access to AWS Organizations.

### SaaS Website

The `saas_web` folder now contains the main SaaS site with signup, login and a
simple management console. Terraform creates an S3 bucket and CloudFront
distribution when `frontend_bucket_name` is set. Upload the contents of
`saas_web` to that bucket and update the `*_API_URL` placeholders (including
`COST_API_URL`) in the Vue components to point at your backend APIs.


To run the SaaS site locally, use the development server with the `--site`
option:

```bash
python3 dev_server.py --site saas_web
```

This serves the files from `saas_web` and mocks the various API endpoints so the
forms and console can be tested without deploying any backend, including a dummy
`/COST_API_URL` used on the console page.
