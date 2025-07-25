variable "bucket_name" {
  type = string
}

variable "domain" {
  description = "Root domain for the site"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
}
