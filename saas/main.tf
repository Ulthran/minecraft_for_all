
module "auth" {
  source               = "./modules/auth"
  user_pool_name       = var.user_pool_name
  client_name          = var.client_name
  account_email_domain = var.account_email_domain
  tenant_scp_id        = aws_organizations_policy.tenant_scp.id
  tenant_ou_id         = aws_organizations_organizational_unit.tenants.id
}

module "frontend_site" {
  source      = "./modules/frontend_site"
  bucket_name = var.frontend_bucket_name
}

locals {
  site_dir   = "${path.root}/../saas_web"
  site_files = fileset(local.site_dir, "**")
  placeholders = {
    "SIGNUP_API_URL"      = module.auth.signup_api_url
    "LOGIN_API_URL"       = module.auth.login_api_url
    "CONFIRM_API_URL"     = module.auth.confirm_api_url
    "USER_POOL_ID"        = module.auth.user_pool_id
    "USER_POOL_CLIENT_ID" = module.auth.user_pool_client_id
  }

  processed_files = {
    for f in local.site_files :
    f => replace(
      replace(
        replace(
          replace(
            replace(
              file("${local.site_dir}/${f}"),
              "SIGNUP_API_URL", local.placeholders["SIGNUP_API_URL"]
            ),
            "LOGIN_API_URL", local.placeholders["LOGIN_API_URL"]
          ),
          "CONFIRM_API_URL", local.placeholders["CONFIRM_API_URL"]
        ),
        "USER_POOL_ID", local.placeholders["USER_POOL_ID"]
      ),
      "USER_POOL_CLIENT_ID", local.placeholders["USER_POOL_CLIENT_ID"]
    )
  }

  mime_types = {
    html = "text/html"
    js   = "application/javascript"
    css  = "text/css"
    vue  = "text/plain"
  }
}

resource "aws_s3_object" "site" {
  for_each = local.processed_files
  bucket   = module.frontend_site.bucket_name
  key      = each.key
  content  = each.value
  content_type = lookup(
    local.mime_types,
    lower(element(reverse(split(".", each.key)), 0)),
    "text/plain",
  )
  etag = md5(each.value)
}
module "tenant_codebuild" {
  source         = "./modules/codebuild_provisioner"
  project_name   = "tenant-terraform"
  repository_url = var.repository_url
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
