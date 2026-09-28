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
  username = var.db_username
  password = var.db_password
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

module "ecs" {
  source = "./modules/ecs"

  project = var.project
  owner   = var.owner
  vpc_id               = module.network.vpc_id
  private_subnet_ids   = module.network.app_subnet_ids
  alb_security_group   = module.security.alb_security_group_id
  ecs_tasks_security_group = module.security.ecs_tasks_security_group_id
  cluster_name         = "${terraform.workspace}-${var.project}"
  api_image            = module.ecr.ecr_image_api
  evaluator_image      = module.ecr.ecr_image_evaluator
  notifier_image       = module.ecr.ecr_image_notifier
  api_container_port   = var.api_port
  api_cpu              = var.api_cpu
  api_memory           = var.api_memory
  worker_cpu            = var.worker_cpu
  worker_memory         = var.worker_memory
  api_min_capacity     = var.api_min_capacity
  api_max_capacity     = var.api_max_capacity
  worker_desired_count = var.worker_desired_count
  db_host              = module.database.db_address
  db_port              = module.database.db_port
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  cache_endpoint       = module.cache.primary_endpoint
  evaluation_queue_url = module.messaging.evaluation_queue_url
  notification_queue_url = module.messaging.notification_queue_url
  audit_queue_url      = module.messaging.audit_queue_url
  tags = local.common_tags
}