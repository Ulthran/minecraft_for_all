variable "user_pool_id" {
  description = "Cognito user pool ID"
  type        = string
}

variable "user_pool_client_id" {
  description = "Cognito user pool client ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "allowed_origins" {
  description = "Origins allowed to call this API"
  type        = list(string)
  validation {
    condition     = alltrue([for origin in var.allowed_origins : can(regex("^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$", origin))])
    error_message = "Each entry in allowed_origins must be a valid URL starting with http:// or https://."
  }
}

variable "stripe_secret_key" {
  description = "Secret key for Stripe API"
  type        = string
}

variable "stripe_price_id" {
  description = "Stripe price ID for subscriptions"
  type        = string
}

variable "domain" {
  description = "Public domain for success/cancel URLs"
  type        = string
}
