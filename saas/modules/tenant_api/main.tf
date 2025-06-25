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
        Effect   = "Allow",
        Action   = ["ec2:DescribeInstances"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ce:GetCostAndUsage"],
        Resource = "*"
      }
    ]
  })
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

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "MC_API"
  auto_deploy = true
}
