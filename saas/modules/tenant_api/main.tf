resource "aws_iam_role" "lambda" {
  name = "minecraft-tenant-api-role"
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

resource "aws_iam_role_policy" "tenant_permissions" {
  name = "tenant-api-permissions"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:GetMetricStatistics"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem"],
        Resource = aws_dynamodb_table.cost_cache.arn
      },
      {
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"],
        Resource = aws_dynamodb_table.server_registry.arn
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${var.backup_bucket_name}"
      }
    ]
  })
}

resource "aws_dynamodb_table" "cost_cache" {
  name         = var.cost_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenant_id"
  range_key    = "server_id"

  attribute {
    name = "tenant_id"
    type = "S"
  }

  attribute {
    name = "server_id"
    type = "S"
  }

  attribute {
    name = "month"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "server_registry" {
  name         = var.server_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenant_id"
  range_key    = "server_id"

  attribute {
    name = "tenant_id"
    type = "S"
  }

  attribute {
    name = "server_id"
    type = "N"
  }
}

# Lambda packages

data "archive_file" "server_status" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/server_status.py"
  output_path = "${path.module}/lambda_server_status.zip"
}

resource "aws_lambda_function" "server_status" {
  filename         = data.archive_file.server_status.output_path
  source_code_hash = data.archive_file.server_status.output_base64sha256
  function_name    = "server-status"
  role             = aws_iam_role.lambda.arn
  handler          = "server_status.handler"
  runtime          = "python3.11"
  timeout          = 10
}

data "archive_file" "cost_report" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/cost_report.py"
  output_path = "${path.module}/lambda_cost_report.zip"
}

resource "aws_lambda_function" "cost_report" {
  filename         = data.archive_file.cost_report.output_path
  source_code_hash = data.archive_file.cost_report.output_base64sha256
  function_name    = "cost-report"
  role             = aws_iam_role.lambda.arn
  handler          = "cost_report.handler"
  runtime          = "python3.11"
  timeout          = 10
  environment {
    variables = {
      COST_TABLE    = aws_dynamodb_table.cost_cache.name
      BACKUP_BUCKET = var.backup_bucket_name
    }
  }
}

data "archive_file" "init_server" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/init_server.py"
  output_path = "${path.module}/lambda_init_server.zip"
}

resource "aws_lambda_function" "init_server" {
  filename         = data.archive_file.init_server.output_path
  source_code_hash = data.archive_file.init_server.output_base64sha256
  function_name    = "init-server"
  role             = aws_iam_role.lambda.arn
  handler          = "init_server.handler"
  runtime          = "python3.11"
  timeout          = 60
  environment {
    variables = {
      SERVER_TABLE = aws_dynamodb_table.server_registry.name
    }
  }
}

data "archive_file" "build_status" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/build_status.py"
  output_path = "${path.module}/lambda_build_status.zip"
}

resource "aws_lambda_function" "build_status" {
  filename         = data.archive_file.build_status.output_path
  source_code_hash = data.archive_file.build_status.output_base64sha256
  function_name    = "build-status"
  role             = aws_iam_role.lambda.arn
  handler          = "build_status.handler"
  runtime          = "python3.11"
  timeout          = 10
}

data "archive_file" "delete_stack" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/delete_stack.py"
  output_path = "${path.module}/lambda_delete_stack.zip"
}

data "archive_file" "resource_metrics" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/resource_metrics.py"
  output_path = "${path.module}/lambda_resource_metrics.zip"
}

resource "aws_lambda_function" "delete_stack" {
  filename         = data.archive_file.delete_stack.output_path
  source_code_hash = data.archive_file.delete_stack.output_base64sha256
  function_name    = "delete-stack"
  role             = aws_iam_role.lambda.arn
  handler          = "delete_stack.handler"
  runtime          = "python3.11"
  timeout          = 60
}

resource "aws_lambda_function" "resource_metrics" {
  filename         = data.archive_file.resource_metrics.output_path
  source_code_hash = data.archive_file.resource_metrics.output_base64sha256
  function_name    = "resource-metrics"
  role             = aws_iam_role.lambda.arn
  handler          = "resource_metrics.handler"
  runtime          = "python3.11"
  timeout          = 10
}

data "archive_file" "ec2_metrics" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/ec2_metrics.py"
  output_path = "${path.module}/lambda_ec2_metrics.zip"
}

resource "aws_lambda_function" "ec2_metrics" {
  filename         = data.archive_file.ec2_metrics.output_path
  source_code_hash = data.archive_file.ec2_metrics.output_base64sha256
  function_name    = "ec2-metrics"
  role             = aws_iam_role.lambda.arn
  handler          = "ec2_metrics.handler"
  runtime          = "python3.11"
  timeout          = 10
}

data "archive_file" "create_checkout_session" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/create_checkout_session.py"
  output_path = "${path.module}/lambda_create_checkout_session.zip"
}

resource "aws_lambda_function" "create_checkout_session" {
  filename         = data.archive_file.create_checkout_session.output_path
  source_code_hash = data.archive_file.create_checkout_session.output_base64sha256
  function_name    = "create-checkout-session"
  role             = aws_iam_role.lambda.arn
  handler          = "create_checkout_session.handler"
  runtime          = "python3.11"
  timeout          = 10
  environment {
    variables = {
      STRIPE_SECRET_KEY = var.stripe_secret_key
      DOMAIN            = var.domain
    }
  }
}

resource "aws_lambda_permission" "apigw_status" {
  statement_id  = "AllowAPIGatewayInvokeStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.server_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_cost" {
  statement_id  = "AllowAPIGatewayInvokeCost"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_report.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_init" {
  statement_id  = "AllowAPIGatewayInvokeInit"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.init_server.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_build_status" {
  statement_id  = "AllowAPIGatewayInvokeBuildStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.build_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_checkout" {
  statement_id  = "AllowAPIGatewayInvokeCheckout"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_checkout_session.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_delete" {
  statement_id  = "AllowAPIGatewayInvokeDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_stack.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_metrics" {
  statement_id  = "AllowAPIGatewayInvokeMetrics"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_metrics.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_ec2_metrics" {
  statement_id  = "AllowAPIGatewayInvokeEc2Metrics"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_metrics.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "this" {
  name          = "tenant-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers     = ["Authorization", "Content-Type"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_origins     = var.allowed_origins
    allow_credentials = true
  }
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "tenant-jwt"
  jwt_configuration {
    audience = [var.user_pool_client_id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${var.user_pool_id}"
  }
}

resource "aws_apigatewayv2_integration" "status" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.server_status.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "cost" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.cost_report.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "init" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.init_server.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "build_status" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.build_status.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "checkout" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.create_checkout_session.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "delete" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.delete_stack.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "metrics" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.resource_metrics.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "ec2_metrics" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_uri        = aws_lambda_function.ec2_metrics.invoke_arn
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "status" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /status"
  target             = "integrations/${aws_apigatewayv2_integration.status.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "cost" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /cost"
  target             = "integrations/${aws_apigatewayv2_integration.cost.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "init" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "POST /init"
  target             = "integrations/${aws_apigatewayv2_integration.init.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "build_status" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /build/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.build_status.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "checkout" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "POST /checkout"
  target             = "integrations/${aws_apigatewayv2_integration.checkout.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "delete" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "POST /delete"
  target             = "integrations/${aws_apigatewayv2_integration.delete.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "metrics" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /metrics"
  target             = "integrations/${aws_apigatewayv2_integration.metrics.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "ec2_metrics" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /ec2"
  target             = "integrations/${aws_apigatewayv2_integration.ec2_metrics.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "MC_API"
  auto_deploy = true
}
