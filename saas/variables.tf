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

variable "stripe_secret_key" {
  description = "Secret key for Stripe"
  type        = string
}

variable "stripe_publishable_key" {
  description = "Publishable key for Stripe"
  type        = string
}

variable "domain" {
  description = "Public domain for payment redirects"
  type        = string
}
