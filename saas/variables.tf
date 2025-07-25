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

variable "zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "minecraft-tfstates"
}


variable "cost_table_name" {
  description = "DynamoDB table name for cached cost reports"
  type        = string
  default     = "minecraft-cost-cache"
}

variable "server_table_name" {
  description = "DynamoDB table tracking tenant servers"
  type        = string
  default     = "minecraft-server-registry"
}
