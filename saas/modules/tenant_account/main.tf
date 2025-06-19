resource "aws_organizations_account" "this" {
  name              = var.account_name
  email             = var.account_email
  close_on_deletion = true
}

provider "aws" {
  alias  = "tenant"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.this.id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_s3_bucket" "web" {
  provider = aws.tenant
  bucket   = "minecraft-web-${var.tenant_id}"
}

output "tenant_account_id" {
  value = aws_organizations_account.this.id
}
