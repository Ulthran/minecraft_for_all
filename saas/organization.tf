resource "aws_organizations_organization" "minecraft" {
  feature_set = "ALL"
}

resource "aws_organizations_policy" "tenant_scp" {
  name        = "TenantRestrictions"
  description = "Restrict tenant accounts to required services"
  content = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Deny",
      NotAction = [
        "ec2:*",
        "s3:*",
        "logs:*",
        "cloudwatch:*",
        "iam:*",
        "lambda:*",
        "apigateway:*",
      ],
      Resource = "*",
    }]
  })
  type = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_organizational_unit" "tenants" {
  name      = "MinecraftTenants"
  parent_id = aws_organizations_organization.minecraft.roots[0].id
}

resource "aws_organizations_policy_attachment" "tenant_ou" {
  policy_id = aws_organizations_policy.tenant_scp.id
  target_id = aws_organizations_organizational_unit.tenants.id
}

output "tenant_ou_id" {
  value = aws_organizations_organizational_unit.tenants.id
}

output "tenant_scp_id" {
  value = aws_organizations_policy.tenant_scp.id
}
