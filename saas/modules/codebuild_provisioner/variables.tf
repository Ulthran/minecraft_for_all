variable "project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "role_name" {
  description = "IAM role name for CodeBuild"
  type        = string
  default     = "tenant-terraform-build"
}

variable "repository_url" {
  description = "Git repository with the Terraform configuration"
  type        = string
}
