resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  lambda_config {
    post_confirmation = aws_lambda_function.create_tenant.arn
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

  inline_policy {
    name = "create-tenant"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect   = "Allow",
        Action   = ["organizations:CreateAccount"],
        Resource = "*"
      }]
    })
  }
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
