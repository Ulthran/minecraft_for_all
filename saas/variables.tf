variable "user_pool_name" {
  type    = string
  default = "minecraft-saas-users"
}

variable "client_name" {
  type    = string
  default = "minecraft-web"
}

variable "frontend_bucket_name" {
  type    = string
  default = "minecraft-saas-frontend"
}

variable "signup_api_url" {
  description = "Endpoint for user signup (Cognito)"
  type        = string
}

variable "login_api_url" {
  description = "Endpoint for user login (Cognito)"
  type        = string
}
