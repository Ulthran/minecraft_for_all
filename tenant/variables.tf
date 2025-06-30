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
  default     = "minecraft-saas-backups"
}

variable "vpc_id" {
  description = "VPC for the security group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the EC2 instance"
  type        = string
}


variable "tenant_id" {
  description = "Unique identifier for the tenant"
  type        = string
}

variable "server_type" {
  description = "Minecraft server type"
  type        = string
  default     = "papermc"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.medium"
}

variable "overworld_border_radius" {
  description = "Overworld border radius"
  type        = number
  default     = 3000
}

variable "nether_border_radius" {
  description = "Nether border radius"
  type        = number
  default     = 3000
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
