
module "auth" {
  source         = "./modules/auth"
  user_pool_name = var.user_pool_name
  client_name    = var.client_name
}

module "frontend_site" {
  source      = "./modules/frontend_site"
  bucket_name = var.frontend_bucket_name
}

module "tenant_account" {
  source               = "./modules/account"
  tenant_account_email = var.tenant_account_email
}

module "backup_bucket" {
  source      = "./modules/backup_bucket"
  bucket_name = var.backup_bucket_name
  tenant_ids  = var.tenant_ids
}

module "terraform_backend" {
  source      = "./modules/state_backend"
  bucket_name = var.state_bucket_name
  table_name  = var.lock_table_name
}

locals {
  site_dir   = "${path.root}/../saas_web"
  site_files = fileset(local.site_dir, "**")
  placeholders = {
    "SIGNUP_API_URL"         = module.auth.signup_api_url
    "LOGIN_API_URL"          = module.auth.login_api_url
    "CONFIRM_API_URL"        = module.auth.confirm_api_url
    "USER_POOL_ID"           = module.auth.user_pool_id
    "USER_POOL_CLIENT_ID"    = module.auth.user_pool_client_id
    "MC_API_URL"             = module.tenant_api.api_url
    "STRIPE_PUBLISHABLE_KEY" = var.stripe_publishable_key
  }

  processed_files = {
    for f in local.site_files :
    f => {
      # PNGs and favicon are binary assets that must be uploaded using base64.
      binary = endswith(lower(f), ".png") || endswith(f, "favicon.ico")
      content = (endswith(lower(f), ".png") || endswith(f, "favicon.ico")) ? filebase64("${local.site_dir}/${f}") : replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      file("${local.site_dir}/${f}"),
                      "MC_API_URL", local.placeholders["MC_API_URL"]
                    ),
                    "SIGNUP_API_URL", local.placeholders["SIGNUP_API_URL"]
                  ),
                  "LOGIN_API_URL", local.placeholders["LOGIN_API_URL"]
                ),
                "LOGIN_API_URL", local.placeholders["LOGIN_API_URL"]
              ),
              "CONFIRM_API_URL", local.placeholders["CONFIRM_API_URL"]
            ),
            "USER_POOL_ID", local.placeholders["USER_POOL_ID"]
          ),
          "USER_POOL_CLIENT_ID", local.placeholders["USER_POOL_CLIENT_ID"]
        ),
        "STRIPE_PUBLISHABLE_KEY", local.placeholders["STRIPE_PUBLISHABLE_KEY"]
      )
    }
  }

  mime_types = {
    html = "text/html"
    js   = "application/javascript"
    css  = "text/css"
    vue  = "text/plain"
    ico  = "image/x-icon"
    png  = "image/png"
  }
}

resource "aws_s3_object" "site" {
  for_each       = local.processed_files
  bucket         = module.frontend_site.bucket_name
  key            = each.key
  content        = each.value.binary ? null : each.value.content
  content_base64 = each.value.binary ? each.value.content : null
  content_type = lookup(
    local.mime_types,
    lower(element(reverse(split(".", each.key)), 0)),
    "text/plain",
  )
  etag = each.value.binary ? filemd5("${local.site_dir}/${each.key}") : md5(each.value.content)
}
module "tenant_codebuild" {
  source            = "./modules/codebuild_provisioner"
  project_name      = "minecraft-tenant-terraform"
  repository_url    = var.repository_url
  state_bucket_name = module.terraform_backend.bucket_name
  lock_table_name   = module.terraform_backend.table_name
}

module "tenant_api" {
  source              = "./modules/tenant_api"
  user_pool_id        = module.auth.user_pool_id
  user_pool_client_id = module.auth.user_pool_client_id
  region              = var.region
  allowed_origins     = ["https://${module.frontend_site.cloudfront_domain}"]
  stripe_secret_key   = var.stripe_secret_key
  domain              = var.domain
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

output "tenant_account_id" {
  value = module.tenant_account.tenant_account_id
}

output "tenant_api_url" {
  value = module.tenant_api.api_url
}

output "backup_bucket" {
  value = module.backup_bucket.bucket_name
}

output "state_bucket" {
  value = module.terraform_backend.bucket_name
}

output "lock_table" {
  value = module.terraform_backend.table_name
}
