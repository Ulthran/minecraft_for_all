terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = "XylBlox"
    }
  }
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
