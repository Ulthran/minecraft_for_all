variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

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


variable "repository_url" {
  description = "Git repository URL with Terraform for tenant infrastructure"
  type        = string
}

