
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
}