resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  lambda_config {
    post_confirmation = aws_lambda_function.post_user_creation_hook.arn
  }

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = false
    require_numbers   = true
    require_symbols   = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Welcome to XylBlox"
    email_message        = <<EOF
Thank you for joining XylBlox!
Your verification code is {####}.
Happy crafting!
EOF
  }

  # Custom attribute storing the tenant identifier assigned during signup
  schema {
    attribute_data_type = "String"
    name                = "tenant_id"
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
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.this.id
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}


resource "aws_iam_role" "lambda" {
  name = "minecraft-post-user-creation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "allow_update_user" {
  name = "minecraft-post-user-creation-userupdate"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["cognito-idp:AdminUpdateUserAttributes"],
      Resource = aws_cognito_user_pool.this.arn
    }]
  })
}

data "archive_file" "lambda_post_user_creation_hook" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/post_user_creation_hook.py"
  output_path = "${path.module}/lambda_post_user_creation_hook.zip"
}

resource "aws_lambda_function" "post_user_creation_hook" {
  filename         = data.archive_file.lambda_post_user_creation_hook.output_path
  source_code_hash = data.archive_file.lambda_post_user_creation_hook.output_base64sha256
  function_name    = "minecraft-post-user-creation-hook"
  role             = aws_iam_role.lambda.arn
  handler          = "post_user_creation_hook.handler"
  runtime          = "python3.11"
  timeout          = 30

}

resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_user_creation_hook.function_name
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

