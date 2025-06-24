resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  lambda_config {
    post_confirmation = aws_lambda_function.create_tenant.arn
  }

  # Custom attribute for the tenant API base URL
  schema {
    attribute_data_type = "String"
    name                = "mc_api_url"
    mutable             = true
  }

  # Once a schema attribute is created it cannot be modified in place.
  # Terraform occasionally tries to update this block when provider
  # defaults change, which results in a failure.  Ignore any changes
  # so that the pool remains intact.
  lifecycle {
    ignore_changes = [schema]
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name                = var.client_name
  user_pool_id        = aws_cognito_user_pool.this.id
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_iam_role" "lambda" {
  name = "create-tenant-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

}
resource "aws_iam_role_policy" "create_tenant" {
  name = "create-tenant"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "organizations:CreateAccount",
        "organizations:DescribeCreateAccountStatus",
        "organizations:ListRoots",
        "organizations:ListOrganizationalUnitsForParent",
        "organizations:CreateOrganizationalUnit",
        "organizations:MoveAccount",
      ],
      Resource = "*",
    }]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_create_tenant" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/create_tenant.py"
  output_path = "${path.module}/lambda_create_tenant.zip"
}

resource "aws_lambda_function" "create_tenant" {
  filename         = data.archive_file.lambda_create_tenant.output_path
  source_code_hash = data.archive_file.lambda_create_tenant.output_base64sha256
  function_name    = "create-tenant"
  role             = aws_iam_role.lambda.arn
  handler          = "create_tenant.handler"
  runtime          = "python3.11"
  timeout          = 30
}

resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_tenant.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn
}

output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.this.id
}

output "signup_api_url" {
  value = "https://${aws_cognito_user_pool.this.endpoint}/signup"
}

output "login_api_url" {
  value = "https://${aws_cognito_user_pool.this.endpoint}/login"
}

output "confirm_api_url" {
  value = "https://${aws_cognito_user_pool.this.endpoint}/confirm"
}
