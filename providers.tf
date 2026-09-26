terraform{
    #Configure the required providers for this Terraform configuration
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  #Configure the backend to store the state file locally
  #The state file can be stored in a remote backend like S3, but for this example, we will store it locally
  backend "s3"{
    bucket = "dev-bucket-itmentorsoft-iac-001"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    profile = "itmentorsoft-terraform-dev"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "itmentorsoft-terraform-dev"
}