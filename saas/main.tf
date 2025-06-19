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

output "tenant_account_id" {
  value = module.tenant_account.tenant_account_id
}

output "user_pool_id" {
  value = module.auth.user_pool_id
}

output "user_pool_client_id" {
  value = module.auth.user_pool_client_id
}
