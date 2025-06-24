resource "aws_organizations_account" "tenants" {
  name  = "minecraft-tenants"
  email = var.tenant_account_email
}
