output "api_url" {
  value = aws_apigatewayv2_stage.prod.invoke_url
}

output "cost_table" {
  value = aws_dynamodb_table.cost_cache.name
}
