locals {
  common_tags = {
    Environment = terraform.workspace
    Owner       = var.owner
    Project     = var.project
  }
}
module "network" {
  source = "./modules/network"
  aws_region = var.aws_region
  vpc_cidr = var.vpc_cidr
  project = var.project
  owner   = var.owner
  availability_zones = var.availability_zones
  public_subnets    = var.public_subnets
  app_subnets       = var.app_subnets
  db_subnets        = var.db_subnets
  tags = local.common_tags
}

module "security" {
  source = "./modules/security"
  project = var.project
  owner   = var.owner
  vpc_id = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
  api_port = var.api_port
  tags    = local.common_tags
}

module "messaging" {
  source = "./modules/messaging"
  project = var.project
  owner   = var.owner
  queues  = var.queues
  tags    = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"
  project = var.project
  owner   = var.owner
  tags    = local.common_tags
}
