resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name
}

resource "aws_cognito_user_pool_client" "this" {
  name                = var.client_name
  user_pool_id        = aws_cognito_user_pool.this.id
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.this.id
}
