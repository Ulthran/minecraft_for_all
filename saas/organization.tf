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

output "tenant_scp_id" {
  value = aws_organizations_policy.tenant_scp.id
}
