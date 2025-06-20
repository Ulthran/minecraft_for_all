# Minecraft Server Infrastructure

This repo contains example infrastructure code for running a Minecraft server on AWS.
It includes both the original CloudFormation template and a Terraform setup with
an EC2 instance, S3 backups and a small Lambda function for starting the server.

## Usage

### CloudFormation demo

```
cd cloudformation
./deploy-stack.sh
```

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
The workflow formats and validates Terraform, lints `user_data.sh` with
ShellCheck, and compiles the Lambda function. You can run the commands locally
if desired:

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

The `saas` directory contains Terraform configuration for creating tenant AWS accounts and a Cognito user pool for authentication. Copy `saas/terraform.tfvars.example` to `saas/terraform.tfvars` and update the values before running `terraform -chdir=saas apply` from a management account that has access to AWS Organizations.

### SaaS Landing Page

The `saas_web` folder holds a small landing page used for the main SaaS sign‑up
site. Terraform creates an S3 bucket and CloudFront distribution when
`frontend_bucket_name` is set. Upload the contents of `saas_web` to that bucket
and update `SIGNUP_API_URL` in `saas_web/app.js` to point at the future signup
API endpoint.
