variable "user_pool_id" {
  description = "Cognito user pool ID"
  type        = string
}

variable "user_pool_client_id" {
  description = "Cognito user pool client ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "allowed_origins" {
  description = "Origins allowed to call this API"
  type        = list(string)
}
