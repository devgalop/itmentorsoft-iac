variable "project" {
  description = "The name of the project"
  type        = string
}

variable "owner" {
  description = "The owner of the resources"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnets"
  type        = list(string)
}

variable "app_subnets" {
  description = "List of application subnets"
  type        = list(string)
}

variable "db_subnets" {
  description = "List of database subnets"
  type        = list(string)
}

variable "api_port" {
  description = "The port on which the API will listen"
  type        = number
}

variable "db_scheduler_start_time" {
  description = "The start time for the RDS instance scheduler in cron format"
  type        = string
}

variable "db_scheduler_stop_time" {
  description = "The stop time for the RDS instance scheduler in cron format"
  type        = string
}

variable "db_name" {
  description = "The name of the RDS database"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the RDS database"
  type        = string
}

variable "db_engine_version" {
  description = "The engine version for the RDS database"
  type        = string
}

variable "multi_az" {
  description = "Whether the RDS database should be multi-AZ"
  type        = bool
}

variable "cache_engine_version" {
  description = "The engine version for the ElastiCache cluster"
  type        = string
}

variable "cache_node_type" {
  description = "The node type for the ElastiCache cluster"
  type        = string
}

variable "worker_cpu" {
  description = "The CPU units for the worker containers (evaluator and notifier)"
  type        = number
}

variable "worker_memory" {
  description = "The memory (in MiB) for the worker containers (evaluator and notifier)"
  type        = number
}

variable "api_cpu" {
  description = "The CPU units for the API container"
  type        = number
}

variable "api_memory" {
  description = "The memory (in MiB) for the API container"
  type        = number
}

variable "api_min_capacity" {
  description = "The minimum number of API container instances"
  type        = number
}

variable "api_max_capacity" {
  description = "The maximum number of API container instances"
  type        = number
}

variable "worker_desired_count" {
  description = "The desired number of worker tasks (evaluator and notifier)"
  type        = number
}

variable "db_username" {
  description = "The master username for the RDS database"
  type        = string
}

variable "db_password" {
  description = "The master password for the RDS database"
  type        = string
}

# Cross-project variables (values provided by infra-base outputs)

variable "ecr_image_api_url" {
  description = "ECR repository URL for the API Docker image, provided by infra-base"
  type        = string
}

variable "ecr_image_evaluator_url" {
  description = "ECR repository URL for the evaluator worker Docker image, provided by infra-base"
  type        = string
}

variable "ecr_image_notifier_url" {
  description = "ECR repository URL for the notifier worker Docker image, provided by infra-base"
  type        = string
}

variable "evaluation_queue_url" {
  description = "URL of the evaluation SQS queue from infra-base"
  type        = string
}

variable "notification_queue_url" {
  description = "URL of the notification SQS queue from infra-base"
  type        = string
}

variable "audit_queue_url" {
  description = "URL of the audit SQS queue from infra-base"
  type        = string
}

variable "github_actions_role_arn" {
  description = "The ARN of the GitHub Actions role"
  type        = string
}
