terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket  = "dev-bucket-itmentorsoft-iac-001"
    key     = "state/base/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "itmentorsoft-terraform-dev"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "itmentorsoft-terraform-dev"
}
