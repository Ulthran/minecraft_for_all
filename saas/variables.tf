variable "tenant_account_name" {
  type = string
}

variable "tenant_account_email" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "user_pool_name" {
  type    = string
  default = "minecraft-saas-users"
}

variable "client_name" {
  type    = string
  default = "minecraft-web"
}

variable "region" {
  type    = string
  default = "us-east-1"
}
