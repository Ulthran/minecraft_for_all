module "tenant_account" {
  source        = "./modules/tenant_account"
  account_name  = var.tenant_account_name
  account_email = var.tenant_account_email
  tenant_id     = var.tenant_id
  region        = var.region
}

module "auth" {
  source         = "./modules/auth"
  user_pool_name = var.user_pool_name
  client_name    = var.client_name
}

module "frontend_site" {
  source      = "./modules/frontend_site"
  bucket_name = var.frontend_bucket_name
}

output "cost_api_url" {
  value = module.tenant_account.cost_api_url
}

output "tenant_account_id" {
  value = module.tenant_account.tenant_account_id
}

output "user_pool_id" {
  value = module.auth.user_pool_id
}

output "user_pool_client_id" {
  value = module.auth.user_pool_client_id
}

output "frontend_bucket" {
  value = module.frontend_site.bucket_name
}

output "frontend_url" {
  value = module.frontend_site.cloudfront_domain
}
