# Security groups for the project resources (ALB, VPC Link, ECS tasks, RDS, Cache)

resource "aws_security_group" "alb" {
  name        = "${terraform.workspace}-sg-${var.project}-alb-001"
  description = "Internal ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from API Gateway VPC Link"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_link.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${terraform.workspace}-sg-${var.project}-alb-001",
    Environment = terraform.workspace,
    Owner = var.owner
  }
}

resource "aws_security_group" "vpc_link" {
  name        = "${terraform.workspace}-sg-${var.project}-vpc-link-001"
  description = "API Gateway VPC Link ENIs"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${terraform.workspace}-sg-${var.project}-vpc-link-001",
    Environment = terraform.workspace,
    Owner = var.owner
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${terraform.workspace}-sg-${var.project}-ecs-tasks-001"
  description = "ECS task security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "API traffic from ALB"
    from_port       = var.api_port
    to_port         = var.api_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-sg-${var.project}-ecs-tasks-001",
    Environment = terraform.workspace,
    Owner = var.owner
  }
}

resource "aws_security_group" "rds" {
  name        = "${terraform.workspace}-sg-${var.project}-rds-001"
  description = "PostgreSQL access from ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${terraform.workspace}-sg-${var.project}-rds-001",
    Environment = terraform.workspace,
    Owner = var.owner
  }
}

resource "aws_security_group" "cache" {
  name        = "${terraform.workspace}-sg-${var.project}-cache-001"
  description = "Valkey access from ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${terraform.workspace}-sg-${var.project}-cache-001",
    Environment = terraform.workspace,
    Owner = var.owner
  }
}

output "alb_security_group_id" { value = aws_security_group.alb.id }
output "api_gateway_vpc_link_security_group_id" { value = aws_security_group.vpc_link.id }
output "ecs_tasks_security_group_id" { value = aws_security_group.ecs_tasks.id }
output "api_security_group_id" { value = aws_security_group.ecs_tasks.id }
output "rds_security_group_id" { value = aws_security_group.rds.id }
output "cache_security_group_id" { value = aws_security_group.cache.id }