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

# Lambda role for cost reporting
resource "aws_iam_role" "cost_lambda" {
  provider = aws.tenant
  name     = "cost-report-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cost_explorer" {
  provider = aws.tenant
  name     = "cost-explorer"
  role     = aws_iam_role.cost_lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["ce:GetCostAndUsage"],
      Resource = "*",
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cost_logs" {
  provider   = aws.tenant
  role       = aws_iam_role.cost_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_cost_report" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/cost_report.py"
  output_path = "${path.module}/lambda_cost_report.zip"
}

resource "aws_lambda_function" "cost_report" {
  provider         = aws.tenant
  filename         = data.archive_file.lambda_cost_report.output_path
  source_code_hash = data.archive_file.lambda_cost_report.output_base64sha256
  function_name    = "cost-report"
  role             = aws_iam_role.cost_lambda.arn
  handler          = "cost_report.handler"
  runtime          = "python3.11"
  timeout          = 10
}

resource "aws_api_gateway_rest_api" "cost" {
  provider = aws.tenant
  name     = "cost-api"
}

resource "aws_api_gateway_resource" "cost" {
  provider    = aws.tenant
  rest_api_id = aws_api_gateway_rest_api.cost.id
  parent_id   = aws_api_gateway_rest_api.cost.root_resource_id
  path_part   = "cost"
}

resource "aws_api_gateway_method" "cost" {
  provider      = aws.tenant
  rest_api_id   = aws_api_gateway_rest_api.cost.id
  resource_id   = aws_api_gateway_resource.cost.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cost" {
  provider                = aws.tenant
  rest_api_id             = aws_api_gateway_rest_api.cost.id
  resource_id             = aws_api_gateway_resource.cost.id
  http_method             = aws_api_gateway_method.cost.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cost_report.invoke_arn
}

resource "aws_lambda_permission" "cost_apigw" {
  provider      = aws.tenant
  statement_id  = "AllowCostAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_report.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.cost.execution_arn
}

resource "aws_api_gateway_deployment" "cost" {
  provider    = aws.tenant
  depends_on  = [aws_api_gateway_integration.cost]
  rest_api_id = aws_api_gateway_rest_api.cost.id
}

resource "aws_api_gateway_stage" "cost" {
  provider      = aws.tenant
  deployment_id = aws_api_gateway_deployment.cost.id
  rest_api_id   = aws_api_gateway_rest_api.cost.id
  stage_name    = "prod"
}

output "tenant_account_id" {
  value = aws_organizations_account.this.id
}

output "cost_api_url" {
  value = aws_api_gateway_stage.cost.invoke_url
}
