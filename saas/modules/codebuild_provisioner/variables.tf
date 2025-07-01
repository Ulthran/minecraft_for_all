variable "project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "role_name" {
  description = "IAM role name for CodeBuild"
  type        = string
  default     = "minecraft-tenant-terraform-build"
}

variable "repository_url" {
  description = "Git repository with the Terraform configuration"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket storing Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table for state locking"
  type        = string
}
