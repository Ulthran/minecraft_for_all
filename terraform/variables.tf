variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}

variable "backup_bucket_name" {
  description = "Unique S3 bucket name for world backups"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the security group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the EC2 instance"
  type        = string
}

variable "web_bucket_name" {
  description = "Unique S3 bucket name for the web interface"
  type        = string
}
