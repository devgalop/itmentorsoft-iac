locals {
  common_tags = {
    Environment = terraform.workspace
    Owner       = var.owner
    Project     = var.project
  }
}

module "ecr" {
  source = "./modules/ecr"

  project                    = var.project
  owner                      = var.owner
  tags                       = local.common_tags
  ecr_repository_names       = var.ecr_repository_names
  github_repositories        = var.github_repositories
  ecr_authorization_actions  = var.ecr_authorization_actions
  ecr_push_actions           = var.ecr_push_actions
}

module "messaging" {
  source = "./modules/messaging"

  project = var.project
  owner   = var.owner
  queues  = var.queues
  tags    = local.common_tags
}

module "audit" {
  source = "./modules/audit"

  project         = var.project
  owner           = var.owner
  audit_queue_arn = module.messaging.audit_queue_arn
  tags            = local.common_tags
}
