terraform {
  backend "s3" {
    bucket       = "minecraft-tfstates"
    key          = "saas/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
