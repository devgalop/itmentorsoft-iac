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

module "ecr" {
  source = "./modules/ecr"
  project = var.project
  owner   = var.owner
  tags    = local.common_tags
}

module "database" {
  source = "./modules/database"
  project = var.project
  owner   = var.owner
  db_scheduler_start_time = var.db_scheduler_start_time
  db_scheduler_stop_time  = var.db_scheduler_stop_time
  db_name = var.db_name
  username = var.username
  password = var.password
  db_instance_class = var.db_instance_class
  db_engine_version = var.db_engine_version
  multi_az = var.multi_az
  subnet_ids = module.network.database_subnet_ids
  security_group_id = module.security.rds_security_group_id
  tags = local.common_tags
}

module "cache" {
  source = "./modules/cache"
  project = var.project
  owner   = var.owner
  subnet_ids = module.network.database_subnet_ids
  engine_version = var.cache_engine_version
  node_type = var.cache_node_type
  security_group_id = module.security.cache_security_group_id
  multi_az = var.multi_az
  tags = local.common_tags
}


module "messaging" {
  source = "./modules/messaging"
  project = var.project
  owner   = var.owner
  queues  = var.queues
  tags    = local.common_tags
}