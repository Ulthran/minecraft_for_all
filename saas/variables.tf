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


variable "tenant_account_email" {
  description = "Email used for the shared tenant AWS account"
  type        = string
}

variable "backup_bucket_name" {
  description = "S3 bucket for centralized tenant backups"
  type        = string
  default     = "minecraft-saas-backups"
}

variable "tenant_ids" {
  description = "List of existing tenant identifiers"
  type        = list(string)
  default     = []
}
