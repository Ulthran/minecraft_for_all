module "auth" {
  source         = "./modules/auth"
  user_pool_name = var.user_pool_name
  client_name    = var.client_name
}

module "frontend_site" {
  source      = "./modules/frontend_site"
  bucket_name = var.frontend_bucket_name
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
