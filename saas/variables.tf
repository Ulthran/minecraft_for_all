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

variable "tenant_account_id" {
  description = "ID of the tenant AWS account for provisioning"
  type        = string
  default     = null
  validation {
    condition     = var.tenant_account_id != null && length(var.tenant_account_id) > 0
    error_message = "The tenant_account_id must be provided and cannot be empty."
  }
}
