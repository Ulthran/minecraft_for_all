variable "bucket_name" {
  description = "Name of the backup bucket"
  type        = string
}

variable "tenant_ids" {
  description = "List of tenants to create folders for"
  type        = list(string)
  default     = []
}
