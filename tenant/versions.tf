terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  # Common tags applied to all AWS resources for this tenant
  common_tags = merge(
    var.tags,
    {
      tenant_id  = var.tenant_id
      CostCenter = var.tenant_id
    }
  )
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.common_tags
  }
}
